from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import psycopg2
import psycopg2.extras
import psycopg2.pool
import hashlib
import random
from datetime import date
import os
import logging
import uuid
import time
import json
import re
import threading
from urllib import request as urlrequest
from urllib import error as urlerror
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
# In production, set SECRET_KEY as an environment variable.
secret_key = os.environ.get('SECRET_KEY')
if not secret_key:
    raise RuntimeError("SECRET_KEY environment variable is required (set it in Render).")
app.secret_key = secret_key

# Basic structured logging for production debugging on Render.
logging.basicConfig(
    level=os.environ.get('LOG_LEVEL', 'INFO').upper(),
    format='%(asctime)s %(levelname)s %(message)s'
)
app.logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO').upper())

DEFAULT_QUIZ_DURATION_MINUTES = 5
MAX_TUTOR_CHAT_CHARS = 400
_db_pool = None
_db_pool_lock = threading.Lock()


class PooledConnection:
    def __init__(self, pool_ref, raw_conn):
        self._pool_ref = pool_ref
        self._raw_conn = raw_conn
        self._closed = False

    def __getattr__(self, item):
        return getattr(self._raw_conn, item)

    def close(self):
        if self._closed:
            return
        self._pool_ref.putconn(self._raw_conn)
        self._closed = True


def initialize_quiz_timer(duration_minutes):
    total_time_sec = max(1, int(duration_minutes)) * 60
    session['quiz_total_time_sec'] = total_time_sec
    session['quiz_started_at'] = int(time.time())
    session['quiz_failed'] = False


def get_remaining_quiz_seconds():
    started_at = session.get('quiz_started_at')
    total_time_sec = session.get('quiz_total_time_sec')
    if not started_at or not total_time_sec:
        return None
    elapsed = max(0, int(time.time()) - int(started_at))
    return max(0, int(total_time_sec) - elapsed)

def get_db():
    global _db_pool
    if _db_pool is None:
        with _db_pool_lock:
            if _db_pool is None:
                min_conn = max(1, int(os.environ.get('DATABASE_POOL_MIN', 1)))
                max_conn = max(min_conn, int(os.environ.get('DATABASE_POOL_MAX', 12)))
                # Prefer Render's DATABASE_URL if available.
                database_url = os.environ.get('DATABASE_URL')
                if database_url:
                    _db_pool = psycopg2.pool.ThreadedConnectionPool(
                        min_conn,
                        max_conn,
                        dsn=database_url,
                        cursor_factory=psycopg2.extras.RealDictCursor
                    )
                else:
                    pg_host = os.environ.get('PGHOST')
                    pg_user = os.environ.get('PGUSER')
                    pg_password = os.environ.get('PGPASSWORD')
                    pg_database = os.environ.get('PGDATABASE')
                    pg_port = int(os.environ.get('PGPORT', 5432))

                    missing = [
                        name
                        for name, value in [
                            ('PGHOST', pg_host),
                            ('PGUSER', pg_user),
                            ('PGPASSWORD', pg_password),
                            ('PGDATABASE', pg_database),
                        ]
                        if not value
                    ]
                    if missing:
                        raise RuntimeError(
                            "Missing required Postgres env vars: "
                            + ", ".join(missing)
                            + " (set them in Render)."
                        )
                    _db_pool = psycopg2.pool.ThreadedConnectionPool(
                        min_conn,
                        max_conn,
                        host=pg_host,
                        user=pg_user,
                        password=pg_password,
                        dbname=pg_database,
                        port=pg_port,
                        cursor_factory=psycopg2.extras.RealDictCursor
                    )
    conn = _db_pool.getconn()
    return PooledConnection(_db_pool, conn)

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()


def sanitize_child_prompt(text):
    cleaned = (text or "").strip()
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned[:MAX_TUTOR_CHAT_CHARS]


def sanitize_for_gemini_text(text):
    # Keep it as plain text, remove control chars that can break JSON/payload parsing.
    raw = (text or "")
    raw = raw.replace("`", "")
    raw = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", raw)
    raw = raw.strip()
    raw = re.sub(r"\s+\n", "\n", raw)
    raw = re.sub(r"\n\s+", "\n", raw)
    return raw


def ensure_ai_tutor_tables(conn):
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS ai_tutor_sessions (
            tutor_session_id TEXT PRIMARY KEY,
            quiz_attempt_id INTEGER NOT NULL,
            student_id INTEGER,
            subject_name TEXT,
            topic_name TEXT,
            score INTEGER NOT NULL,
            total_questions INTEGER NOT NULL,
            performance_summary TEXT NOT NULL,
            pattern_summary TEXT NOT NULL,
            misconception_summary TEXT NOT NULL,
            study_plan_json JSONB NOT NULL DEFAULT '[]'::jsonb,
            context_json JSONB NOT NULL,
            wrong_question_ids_json JSONB NOT NULL DEFAULT '[]'::jsonb,
            unlocked BOOLEAN NOT NULL DEFAULT TRUE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS ai_tutor_messages (
            message_id BIGSERIAL PRIMARY KEY,
            tutor_session_id TEXT NOT NULL REFERENCES ai_tutor_sessions(tutor_session_id) ON DELETE CASCADE,
            role TEXT NOT NULL CHECK (role IN ('assistant', 'user')),
            message_text TEXT NOT NULL,
            meta_json JSONB NOT NULL DEFAULT '{}'::jsonb,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS ai_tutor_redemptions (
            redemption_id BIGSERIAL PRIMARY KEY,
            tutor_session_id TEXT NOT NULL REFERENCES ai_tutor_sessions(tutor_session_id) ON DELETE CASCADE,
            question_text TEXT NOT NULL,
            answer_text TEXT NOT NULL,
            student_answer TEXT,
            is_correct BOOLEAN,
            awarded_points INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    cur.close()


def option_text_from_label(q, label):
    if label == 'A':
        return q.get('option_a', '')
    if label == 'B':
        return q.get('option_b', '')
    if label == 'C':
        return q.get('option_c', '')
    if label == 'D':
        return q.get('option_d', '')
    return ''


def generate_study_plan(topic_name):
    base = [
        f"{topic_name} basics",
        f"{topic_name} practice",
        f"Word problems with {topic_name.lower()}",
    ]
    if 'division' in topic_name.lower():
        base = ['Multiplication facts', 'Long division', 'Sharing word problems']
    elif 'fraction' in topic_name.lower():
        base = ['Equivalent fractions', 'Adding fractions', 'Fraction story problems']
    elif 'multiplication' in topic_name.lower():
        base = ['Multiplication tables', 'Arrays and groups', 'Mixed operations']
    return base[:3]


def build_tutor_analysis(score, total, subject_name, topic_name, review_rows):
    wrong_rows = [row for row in review_rows if not row['is_correct']]
    summary = f"You got {score} out of {total} correct. Great effort! Let's level up together."
    if not wrong_rows:
        pattern = f"Amazing! You are strong in {topic_name}."
        misconception = "No repeated mistakes found. Keep practicing to stay sharp!"
    else:
        common_user = {}
        common_correct = {}
        for row in wrong_rows:
            common_user[row['user']] = common_user.get(row['user'], 0) + 1
            common_correct[row['correct']] = common_correct.get(row['correct'], 0) + 1
        biggest_user = max(common_user.items(), key=lambda item: item[1])[0]
        biggest_correct = max(common_correct.items(), key=lambda item: item[1])[0]
        pattern = f"You seem to need more practice in {topic_name}, especially when answer choices look similar."
        misconception = (
            f"I noticed a pattern: option {biggest_user} was often picked when option {biggest_correct} was correct. "
            "Let's slow down and compare each option carefully."
        )
    return {
        'performance_summary': summary,
        'pattern_summary': pattern,
        'misconception_summary': misconception,
        'study_plan': generate_study_plan(topic_name),
        'wrong_rows': wrong_rows,
        'subject_name': subject_name,
        'topic_name': topic_name
    }


def make_initial_tutor_message(analysis):
    lines = [
        "Hi! I am your AI Tutor. 🌟",
        analysis['performance_summary'],
        analysis['pattern_summary'],
        analysis['misconception_summary'],
        "Try these next topics:",
    ]
    for item in analysis['study_plan']:
        lines.append(f"- {item}")
    lines.append("Tap a wrong question below and I will explain it step by step.")
    return "\n".join(lines)


def call_external_ai_if_available(context_payload, user_message):
    api_key = os.environ.get('OPENAI_API_KEY', '').strip()
    if not api_key:
        return None
    payload = {
        "model": os.environ.get('OPENAI_MODEL', 'gpt-4o-mini'),
        "temperature": 0.3,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are a friendly AI Tutor for grades 1-5. Use simple words, short sentences, and kid-safe tone. "
                    "Be accurate. Avoid jargon. Keep responses under 120 words."
                )
            },
            {
                "role": "user",
                "content": f"Session context: {json.dumps(context_payload)}\nStudent says: {user_message}"
            }
        ]
    }
    req = urlrequest.Request(
        "https://api.openai.com/v1/chat/completions",
        data=json.dumps(payload).encode('utf-8'),
        method='POST',
        headers={
            'Content-Type': 'application/json',
            'Authorization': f"Bearer {api_key}",
        }
    )
    try:
        with urlrequest.urlopen(req, timeout=12) as resp:
            body = resp.read().decode('utf-8')
        parsed = json.loads(body)
        return parsed['choices'][0]['message']['content'].strip()
    except Exception:
        app.logger.exception("ai_tutor_external_api_failed")
        return None


def save_tutor_message(cur, tutor_session_id, role, message_text, meta=None):
    cur.execute("""
        INSERT INTO ai_tutor_messages (tutor_session_id, role, message_text, meta_json)
        VALUES (%s, %s, %s, %s::jsonb)
    """, (tutor_session_id, role, message_text, json.dumps(meta or {})))


def get_tutor_conversation_history(cur, tutor_session_id):
    cur.execute("""
        SELECT role, message_text
        FROM ai_tutor_messages
        WHERE tutor_session_id = %s
        ORDER BY created_at ASC, message_id ASC
        LIMIT 100
    """, (tutor_session_id,))
    rows = cur.fetchall()
    history = []
    for row in rows:
        role = 'model' if row.get('role') == 'assistant' else 'user'
        text = sanitize_for_gemini_text(row.get('message_text', ''))
        if text:
            history.append({'role': role, 'text': text})
    return history


def build_gemini_system_prompt(topic_name, subject_name):
    return f"""
You are Sprout 🌱 — the friendly AI learning buddy of MindSprouts, made for primary school kids (Grade 1 to Grade 5).
The student just finished a quiz on: "{topic_name}" (Subject: "{subject_name}").
YOUR PERSONALITY:
- You are like a fun, caring older sibling who loves helping with studies
- Talk casually and warmly — like a real friend, not a teacher
- Use simple words, short sentences, emojis occasionally 😊
- Be encouraging, never make the student feel bad for wrong answers
- Celebrate when they get things right!
WHAT YOU DO:
- Answer ANY question related to school subjects freely and naturally
  (Maths, Science, EVS, English, GK, AI, Computers, History, Geography etc.)
- If student asks "why is your answer right?" or "how is that correct?" —
  explain it step by step in a simple, friendly way with a real-life example
- If student asks to explain a wrong question — explain clearly why their
  answer was wrong AND why the correct answer is right, use examples
- Keep conversation going naturally — ask follow-up questions like a buddy would
- Remember everything said in this conversation and build on it
WHAT YOU DON'T DO:
- Never discuss movies, games, anime, celebrities, social media, cricket scores,
  news, politics, or anything not related to studying
- If student asks off-topic stuff, say something like:
  "Haha nice try! 😄 But it's learning time, not fun time!
   Ask me anything about {topic_name} or any school subject — I got you! 📚"
- Never repeat the same response twice
- Never give generic tips — always answer the EXACT question asked
REMEMBER:
- You have the full chat history — use it to give connected, relevant answers
- Be a buddy, not a bot — respond naturally like a real conversation
- Short responses are fine — you don't need to write essays for every answer
""".strip()


def call_gemini_with_history(topic_name, subject_name, history_items):
    api_key = (
        os.environ.get('GEMINI_API_KEY', '').strip()
        or os.environ.get('GOOGLE_API_KEY', '').strip()
    )
    if not api_key:
        return None, "Missing GEMINI_API_KEY (or GOOGLE_API_KEY)"
    model_name = os.environ.get('GEMINI_MODEL', 'gemini-2.0-flash')
    contents = []
    for item in history_items:
        role = item.get('role', 'user')
        text = sanitize_for_gemini_text(item.get('text', ''))
        if not text:
            continue
        gemini_role = 'model' if role == 'model' else 'user'
        contents.append({
            "role": gemini_role,
            "parts": [{"text": text}]
        })
    # Merge consecutive same-role messages — Gemini requires strictly alternating turns.
    merged = []
    for turn in contents:
        if merged and merged[-1]['role'] == turn['role']:
            merged[-1]['parts'][0]['text'] = merged[-1]['parts'][0]['text'] + ' ' + turn['parts'][0]['text']
        else:
            merged.append(turn)
    contents = merged
    # Gemini requires the first turn to be from the user.
    while contents and contents[0].get('role') == 'model':
        contents.pop(0)
    if not contents:
        return None, "Empty conversation history"
    payload = {
        "system_instruction": {
            "parts": [{"text": build_gemini_system_prompt(topic_name, subject_name)}]
        },
        "contents": contents
    }
    # Log payload for debugging (safe: no API key included).
    try:
        app.logger.info("gemini_payload %s", json.dumps(payload, ensure_ascii=False)[:6000])
    except Exception:
        app.logger.exception("gemini_payload_log_failed")
    endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
    req = urlrequest.Request(
        endpoint,
        data=json.dumps(payload).encode('utf-8'),
        method='POST',
        headers={'Content-Type': 'application/json'}
    )
    try:
        with urlrequest.urlopen(req, timeout=18) as resp:
            body = resp.read().decode('utf-8')
        parsed = json.loads(body)
        text = (
            parsed.get('candidates', [{}])[0]
            .get('content', {})
            .get('parts', [{}])[0]
            .get('text', '')
            .strip()
        )
        if not text:
            return None, "Gemini returned empty response"
        return text, None
    except urlerror.HTTPError as http_err:
        try:
            body = http_err.read().decode('utf-8')
        except Exception:
            body = ''
        app.logger.error("gemini_chat_http_error status=%s body=%s", http_err.code, body)
        short_reason = body[:400] if body else 'no body'
        return None, "Gemini request failed (" + str(http_err.code) + "): " + short_reason
    except Exception:
        app.logger.exception("gemini_chat_failed")
        return None, "Gemini request failed"

def ensure_app_settings_table(conn):
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        )
    """)
    conn.commit()
    cur.close()

def get_quiz_duration_minutes(conn):
    ensure_app_settings_table(conn)
    cur = conn.cursor()
    cur.execute("SELECT value FROM app_settings WHERE key = %s", ('quiz_duration_minutes',))
    row = cur.fetchone()
    if row and row.get('value'):
        try:
            return max(1, int(row['value']))
        except (ValueError, TypeError):
            return DEFAULT_QUIZ_DURATION_MINUTES
    return DEFAULT_QUIZ_DURATION_MINUTES

def set_quiz_duration_minutes(conn, minutes):
    ensure_app_settings_table(conn)
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO app_settings (key, value)
        VALUES (%s, %s)
        ON CONFLICT (key)
        DO UPDATE SET value = EXCLUDED.value
    """, ('quiz_duration_minutes', str(minutes)))
    conn.commit()
    cur.close()


def fetch_topics_for_subject_with_grade_fallback(cur, subject_id, grade):
    cur.execute(
        "SELECT * FROM topics WHERE subject_id = %s AND grade = %s ORDER BY topic_name",
        (subject_id, grade),
    )
    topics = cur.fetchall()
    if topics:
        return topics
    cur.execute(
        "SELECT * FROM topics WHERE subject_id = %s ORDER BY grade, topic_name",
        (subject_id,),
    )
    return cur.fetchall()


def count_topics_for_subject_with_grade_fallback(cur, subject_id, grade):
    cur.execute(
        "SELECT COUNT(*) AS total FROM topics WHERE subject_id = %s AND grade = %s",
        (subject_id, grade),
    )
    total_topics = cur.fetchone()['total']
    if total_topics > 0:
        return total_topics
    cur.execute("SELECT COUNT(*) AS total FROM topics WHERE subject_id = %s", (subject_id,))
    return cur.fetchone()['total']

def student_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'student_id' not in session:
            flash('Please login first.', 'warning')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated

def admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'admin_id' not in session:
            flash('Admin login required.', 'warning')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated

def super_admin_required(f):
    from functools import wraps
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'admin_id' not in session or not session.get('is_super_admin'):
            flash('Super Admin access required.', 'danger')
            return redirect(url_for('admin_dashboard'))
        return f(*args, **kwargs)
    return decorated


@app.before_request
def log_request_start():
    app.logger.info("request_start method=%s path=%s", request.method, request.path)

@app.after_request
def log_request_end(response):
    app.logger.info(
        "request_end method=%s path=%s status=%s",
        request.method,
        request.path,
        response.status_code
    )
    return response

@app.route('/health')
def health():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT 1 AS ok")
        result = cur.fetchone()
        cur.close()
        conn.close()
        if result and result.get('ok') == 1:
            return {'status': 'ok', 'database': 'up'}, 200
        return {'status': 'degraded', 'database': 'unexpected_response'}, 503
    except Exception:
        app.logger.exception("health_check_failed")
        return {'status': 'error', 'database': 'down'}, 503

@app.route('/live')
def live():
    # Liveness probe: process is up, no database dependency.
    return {'status': 'alive'}, 200

@app.route('/')
def landing():
    """Landing / promotional page shown before login."""
    # If already logged in, skip landing and go straight to dashboard
    if 'student_id' in session:
        return redirect(url_for('student_dashboard'))
    if 'admin_id' in session:
        return redirect(url_for('admin_dashboard'))
    return render_template('landing.html')
 
 
# ── LOGIN PAGE ROUTE — the existing login/signup page ─────────
@app.route('/login')
def login():
    """Login & sign-up page (was previously served at '/')."""
    # If already logged in, skip to dashboard
    if 'student_id' in session:
        return redirect(url_for('student_dashboard'))
    if 'admin_id' in session:
        return redirect(url_for('admin_dashboard'))
    return render_template('index.html') 


@app.route('/index')
def index():
    # Backward-compatible endpoint used by older redirects.
    return redirect(url_for('login'))

@app.route('/signup', methods=['POST'])
def signup():
    display_name = request.form['display_name'].strip()
    username     = request.form['username'].strip().lower()
    password     = request.form['password']
    grade        = int(request.form['grade'])
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT student_id FROM students WHERE username = %s", (username,))
    if cur.fetchone():
        flash('Username already taken!', 'danger')
        cur.close(); conn.close()
        return redirect(url_for('index'))
    cur.execute("""
        INSERT INTO students (display_name, username, password_hash, grade)
        VALUES (%s, %s, %s, %s)
    """, (display_name, username, hash_password(password), grade))
    conn.commit()
    cur.close(); conn.close()
    flash('Account created! Please login.', 'success')
    return redirect(url_for('index'))

@app.route('/student_login', methods=['POST'])
def student_login():
    username = request.form['username'].strip().lower()
    password = request.form['password']
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM students WHERE username = %s AND password_hash = %s",
                (username, hash_password(password)))
    student = cur.fetchone()
    cur.close(); conn.close()
    if student:
        session['student_id']     = student['student_id']
        session['display_name']   = student['display_name']
        session['grade']          = student['grade']
        session['total_points']   = student['total_points']
        session['current_streak'] = student['current_streak']
        session['longest_streak'] = student['longest_streak']
        session['timer_enabled']  = False
        return redirect(url_for('student_dashboard'))
    flash('Wrong username or password!', 'danger')
    return redirect(url_for('index'))

@app.route('/admin_login', methods=['POST'])
def admin_login():
    username = request.form['username'].strip().lower()
    password = request.form['password']
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM admins WHERE username = %s AND password_hash = %s",
                (username, hash_password(password)))
    admin = cur.fetchone()
    cur.close(); conn.close()
    if admin:
        session['admin_id']       = admin['admin_id']
        session['display_name']   = admin['display_name']
        session['is_super_admin'] = admin['is_super_admin']
        return redirect(url_for('admin_dashboard'))
    flash('Wrong admin credentials!', 'danger')
    return redirect(url_for('index'))

@app.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'success')
    return redirect(url_for('index'))

@app.route('/toggle_timer')
@student_required
def toggle_timer():
    session['timer_enabled'] = not session.get('timer_enabled', False)
    return redirect(request.referrer or url_for('student_dashboard'))

@app.route('/dashboard')
@student_required
def student_dashboard():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM subjects")
    subjects = cur.fetchall()
    cur.execute("SELECT COUNT(*) AS total FROM results WHERE student_id = %s",
                (session['student_id'],))
    total_quizzes = cur.fetchone()['total']
    cur.close(); conn.close()
    return render_template(
        'student_dash.html',
        subjects=subjects,
        total_quizzes=total_quizzes,
        ai_tutor_locked=True
    )

@app.route('/topics/<int:subject_id>')
@student_required
def topics(subject_id):
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM subjects WHERE subject_id = %s", (subject_id,))
    subject = cur.fetchone()
    topics = fetch_topics_for_subject_with_grade_fallback(cur, subject_id, session['grade'])
    cur.execute("""
        SELECT DISTINCT topic_name FROM results
        WHERE student_id = %s AND subject_name = %s
    """, (session['student_id'], subject['subject_name']))
    attempted = [r['topic_name'] for r in cur.fetchall()]
    cur.close(); conn.close()
    return render_template(
        'topics.html',
        subject=subject,
        topics=topics,
        attempted=attempted,
        ai_tutor_locked=True
    )

@app.route('/quiz/<int:topic_id>')
@student_required
def quiz(topic_id):
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM topics WHERE topic_id = %s", (topic_id,))
    topic = cur.fetchone()
    cur.execute("SELECT * FROM questions WHERE topic_id = %s", (topic_id,))
    all_questions = cur.fetchall()
    questions = random.sample(all_questions, min(10, len(all_questions)))
    session['quiz_questions']    = [q['question_id'] for q in questions]
    session['quiz_topic_id']     = topic_id
    session['quiz_topic_name']   = topic['topic_name']
    session['quiz_attempt_token'] = str(uuid.uuid4())
    session['quiz_submitted'] = False
    cur.execute("""
        SELECT s.subject_name FROM subjects s
        JOIN topics t ON s.subject_id = t.subject_id
        WHERE t.topic_id = %s
    """, (topic_id,))
    subj = cur.fetchone()
    quiz_duration_minutes = get_quiz_duration_minutes(conn)
    cur.close(); conn.close()
    session['quiz_subject_name'] = subj['subject_name']
    initialize_quiz_timer(quiz_duration_minutes)
    return render_template(
        'quiz.html',
        questions=questions,
        topic=topic,
        ai_tutor_locked=True,
        quiz_duration_minutes=quiz_duration_minutes,
        total_time_sec=session.get('quiz_total_time_sec', quiz_duration_minutes * 60),
        remaining_time_sec=get_remaining_quiz_seconds()
    )


@app.route('/quiz/failed')
@student_required
def quiz_failed():
    if not session.get('quiz_topic_id'):
        flash('No active quiz found. Start a topic to continue.', 'warning')
        return redirect(url_for('student_dashboard'))
    session['quiz_failed'] = True
    return render_template('quiz_failed.html', topic_name=session.get('quiz_topic_name', 'Quiz'))

@app.route('/submit_quiz', methods=['POST'])
@student_required
def submit_quiz():
    question_ids = session.get('quiz_questions', [])
    topic_name   = session.get('quiz_topic_name')
    subject_name = session.get('quiz_subject_name')
    submitted_token = request.form.get('quiz_attempt_token', '')
    active_token = session.get('quiz_attempt_token', '')
    if not question_ids or not topic_name or not subject_name:
        flash('Quiz session expired. Please start the quiz again.', 'warning')
        return redirect(url_for('student_dashboard'))
    if session.get('quiz_submitted'):
        flash('This quiz was already submitted once.', 'info')
        return redirect(url_for('history'))
    if not submitted_token or submitted_token != active_token:
        flash('Invalid or expired quiz submission. Please retake the quiz.', 'warning')
        return redirect(url_for('student_dashboard'))
    if session.get('quiz_failed'):
        return redirect(url_for('quiz_failed'))
    remaining_time_sec = get_remaining_quiz_seconds()
    if remaining_time_sec is not None and remaining_time_sec <= 0:
        session['quiz_failed'] = True
        return redirect(url_for('quiz_failed'))
    session['quiz_submitted'] = True
    conn = get_db()
    cur  = conn.cursor()
    score  = 0
    review = []
    for qid in question_ids:
        cur.execute("SELECT * FROM questions WHERE question_id = %s", (qid,))
        q = cur.fetchone()
        user_answer = request.form.get(f'q_{qid}', '')
        is_correct  = user_answer.upper() == q['correct_option'].upper()
        if is_correct:
            score += 1
        review.append({
            'question_id': qid,
            'question':   q['question_text'],
            'option_a':   q['option_a'],
            'option_b':   q['option_b'],
            'option_c':   q['option_c'],
            'option_d':   q['option_d'],
            'correct':    q['correct_option'],
            'user':       user_answer.upper() if user_answer else '-',
            'is_correct': is_correct
        })
    total         = len(question_ids)
    points_earned = score * 10
    cur.execute("""
        SELECT current_streak, longest_streak, last_quiz_date
        FROM students WHERE student_id = %s
    """, (session['student_id'],))
    s = cur.fetchone()
    today          = date.today()
    last_date      = s['last_quiz_date']
    current_streak = s['current_streak']
    longest_streak = s['longest_streak']
    if last_date is None:
        current_streak = 1
    elif last_date == today:
        pass
    elif (today - last_date).days == 1:
        current_streak += 1
    else:
        current_streak = 1
    if current_streak > longest_streak:
        longest_streak = current_streak
    cur.execute("""
        INSERT INTO results
        (student_id, student_name, subject_name, topic_name, grade, score, total_questions)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING result_id
    """, (session['student_id'], session['display_name'],
          subject_name, topic_name, session['grade'], score, total))
    inserted_result = cur.fetchone()
    quiz_attempt_id = inserted_result['result_id']
    cur.execute("""
        UPDATE students
        SET total_points   = total_points + %s,
            current_streak = %s,
            longest_streak = %s,
            last_quiz_date = %s
        WHERE student_id = %s
    """, (points_earned, current_streak, longest_streak, today, session['student_id']))
    analysis = build_tutor_analysis(score, total, subject_name, topic_name, review)
    tutor_session_id = str(uuid.uuid4())
    session_context = {
        'quiz_attempt_id': quiz_attempt_id,
        'student_id': session.get('student_id'),
        'subject': subject_name,
        'topic': topic_name,
        'questions': [
            {
                'question_id': qid,
                'question_text': row['question'],
                'selected_option': row['user'],
                'selected_answer': option_text_from_label(row, row['user']),
                'correct_option': row['correct'],
                'correct_answer': option_text_from_label(row, row['correct']),
                'is_correct': row['is_correct']
            }
            for qid, row in zip(question_ids, review)
        ]
    }
    ensure_ai_tutor_tables(conn)
    cur.execute("""
        INSERT INTO ai_tutor_sessions (
            tutor_session_id, quiz_attempt_id, student_id, subject_name, topic_name, score, total_questions,
            performance_summary, pattern_summary, misconception_summary, study_plan_json, context_json, wrong_question_ids_json
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb, %s::jsonb, %s::jsonb)
    """, (
        tutor_session_id,
        quiz_attempt_id,
        session.get('student_id'),
        subject_name,
        topic_name,
        score,
        total,
        analysis['performance_summary'],
        analysis['pattern_summary'],
        analysis['misconception_summary'],
        json.dumps(analysis['study_plan']),
        json.dumps(session_context),
        json.dumps([q['question_id'] for q in session_context['questions'] if not q['is_correct']])
    ))
    initial_message = make_initial_tutor_message(analysis)
    save_tutor_message(cur, tutor_session_id, 'assistant', initial_message, {'type': 'auto_analysis'})
    conn.commit()
    cur.close(); conn.close()
    session['total_points']   = session.get('total_points', 0) + points_earned
    session['current_streak'] = current_streak
    session['longest_streak'] = longest_streak
    session['ai_tutor_session_id'] = tutor_session_id
    session['ai_tutor_quiz_attempt_id'] = quiz_attempt_id
    session.pop('quiz_total_time_sec', None)
    session.pop('quiz_started_at', None)
    session.pop('quiz_failed', None)
    return render_template('result.html',
        score=score, total=total,
        points_earned=points_earned,
        topic_name=topic_name,
        subject_name=subject_name,
        review=review,
        current_streak=current_streak,
        ai_tutor_locked=False,
        tutor_session_id=tutor_session_id,
        quiz_attempt_id=quiz_attempt_id)

@app.route('/history')
@student_required
def history():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM results WHERE student_id = %s ORDER BY attempted_at DESC",
                (session['student_id'],))
    results = cur.fetchall()
    cur.close(); conn.close()
    return render_template('history.html', results=results)

@app.route('/leaderboard')
@student_required
def leaderboard():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("""
        SELECT display_name, grade, total_points, current_streak
        FROM students ORDER BY total_points DESC LIMIT 10
    """)
    leaders = cur.fetchall()
    cur.close(); conn.close()
    return render_template('leaderboard.html', leaders=leaders)

@app.route('/progress')
@student_required
def progress():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM subjects")
    subjects = cur.fetchall()
    subject_progress = []
    for subj in subjects:
        total_topics = count_topics_for_subject_with_grade_fallback(
            cur,
            subj['subject_id'],
            session['grade'],
        )
        cur.execute("""
            SELECT COUNT(DISTINCT topic_name) AS attempted FROM results
            WHERE student_id = %s AND subject_name = %s
        """, (session['student_id'], subj['subject_name']))
        attempted = cur.fetchone()['attempted']
        pct = int((attempted / total_topics * 100)) if total_topics > 0 else 0
        cur.execute("""
            SELECT AVG(score / total_questions * 100) AS avg_score FROM results
            WHERE student_id = %s AND subject_name = %s
        """, (session['student_id'], subj['subject_name']))
        avg = cur.fetchone()['avg_score']
        subject_progress.append({
            'subject_name': subj['subject_name'],
            'icon':         subj['icon'],
            'color_class':  subj['color_class'],
            'total_topics': total_topics,
            'attempted':    attempted,
            'pct':          pct,
            'avg_score':    round(avg) if avg else 0
        })
    cur.execute("""
        SELECT topic_name, subject_name, score, total_questions, attempted_at
        FROM results WHERE student_id = %s
        ORDER BY attempted_at DESC LIMIT 10
    """, (session['student_id'],))
    recent_results = cur.fetchall()
    cur.execute("SELECT current_streak, longest_streak, total_points FROM students WHERE student_id = %s",
                (session['student_id'],))
    stats = cur.fetchone()
    cur.close(); conn.close()
    return render_template('progress.html',
        subject_progress=subject_progress,
        recent_results=recent_results,
        stats=stats)

@app.route('/profile')
@student_required
def profile():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM students WHERE student_id = %s", (session['student_id'],))
    student = cur.fetchone()
    cur.execute("SELECT COUNT(*) AS total FROM results WHERE student_id = %s",
                (session['student_id'],))
    total_quizzes = cur.fetchone()['total']
    cur.execute("""
        SELECT subject_name, COUNT(*) AS count,
               AVG(score/total_questions*100) AS avg_score
        FROM results WHERE student_id = %s GROUP BY subject_name
    """, (session['student_id'],))
    subject_stats = cur.fetchall()
    cur.close(); conn.close()
    return render_template('profile.html',
        student=student,
        total_quizzes=total_quizzes,
        subject_stats=subject_stats)

@app.route('/change_password', methods=['POST'])
@student_required
def change_password():
    current_pw = request.form['current_password']
    new_pw     = request.form['new_password']
    confirm_pw = request.form['confirm_password']
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT student_id FROM students WHERE student_id = %s AND password_hash = %s",
                (session['student_id'], hash_password(current_pw)))
    valid = cur.fetchone()
    if not valid:
        flash('Current password is incorrect!', 'danger')
    elif new_pw != confirm_pw:
        flash('New passwords do not match!', 'danger')
    elif len(new_pw) < 4:
        flash('Password must be at least 4 characters!', 'danger')
    else:
        cur.execute("UPDATE students SET password_hash = %s WHERE student_id = %s",
                    (hash_password(new_pw), session['student_id']))
        conn.commit()
        flash('Password changed successfully!', 'success')
    cur.close(); conn.close()
    return redirect(url_for('profile'))

@app.route('/admin')
@admin_required
def admin_dashboard():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT COUNT(*) AS total FROM students")
    total_students = cur.fetchone()['total']
    cur.execute("SELECT COUNT(*) AS total FROM questions")
    total_questions = cur.fetchone()['total']
    cur.execute("SELECT COUNT(*) AS total FROM results")
    total_results = cur.fetchone()['total']
    cur.execute("SELECT * FROM results ORDER BY attempted_at DESC LIMIT 10")
    recent = cur.fetchall()
    quiz_duration_minutes = get_quiz_duration_minutes(conn)
    cur.close(); conn.close()
    return render_template('admin_dash.html',
        total_students=total_students,
        total_questions=total_questions,
        total_results=total_results,
        recent=recent,
        quiz_duration_minutes=quiz_duration_minutes)

@app.route('/admin/quiz-duration', methods=['POST'])
@admin_required
def update_quiz_duration():
    raw_minutes = request.form.get('quiz_duration_minutes', '').strip()
    try:
        minutes = int(raw_minutes)
    except ValueError:
        flash('Please enter a valid duration in minutes.', 'danger')
        return redirect(url_for('admin_dashboard'))
    if minutes < 1 or minutes > 180:
        flash('Quiz duration must be between 1 and 180 minutes.', 'danger')
        return redirect(url_for('admin_dashboard'))
    conn = get_db()
    set_quiz_duration_minutes(conn, minutes)
    conn.close()
    flash('Quiz duration updated successfully.', 'success')
    return redirect(url_for('admin_dashboard'))


@app.route('/admin/ai-diagnostics')
@admin_required
def admin_ai_diagnostics():
    has_gemini_key = bool(os.environ.get('GEMINI_API_KEY', '').strip())
    has_google_key = bool(os.environ.get('GOOGLE_API_KEY', '').strip())
    return jsonify({
        'ok': True,
        'gemini': {
            'key_configured': has_gemini_key or has_google_key,
            'key_source': 'GEMINI_API_KEY' if has_gemini_key else ('GOOGLE_API_KEY' if has_google_key else None),
            'model': os.environ.get('GEMINI_MODEL', 'gemini-2.0-flash')
        },
        'database_pool': {
            'min': max(1, int(os.environ.get('DATABASE_POOL_MIN', 1))),
            'max': max(max(1, int(os.environ.get('DATABASE_POOL_MIN', 1))), int(os.environ.get('DATABASE_POOL_MAX', 12)))
        }
    }), 200

@app.route('/admin/questions')
@admin_required
def manage_questions():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("""
        SELECT q.*, t.topic_name, t.grade, s.subject_name
        FROM questions q
        JOIN topics t ON q.topic_id = t.topic_id
        JOIN subjects s ON t.subject_id = s.subject_id
        ORDER BY s.subject_name, t.grade, t.topic_name
    """)
    questions = cur.fetchall()
    cur.execute("""
        SELECT t.*, s.subject_name FROM topics t
        JOIN subjects s ON t.subject_id = s.subject_id
        ORDER BY s.subject_name, t.grade
    """)
    topics = cur.fetchall()
    cur.close(); conn.close()
    return render_template('manage_questions.html', questions=questions, topics=topics)

@app.route('/admin/topics')
@admin_required
def manage_topics():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM subjects ORDER BY subject_name")
    subjects = cur.fetchall()
    quiz_duration_minutes = get_quiz_duration_minutes(conn)
    cur.execute("""
        SELECT t.*, s.subject_name
        FROM topics t
        JOIN subjects s ON t.subject_id = s.subject_id
        ORDER BY t.grade, s.subject_name, t.topic_name
    """)
    topics = cur.fetchall()
    cur.close(); conn.close()
    return render_template(
        'manage_topics.html',
        topics=topics,
        subjects=subjects,
        quiz_duration_minutes=quiz_duration_minutes
    )

@app.route('/admin/topics/add', methods=['POST'])
@admin_required
def add_topic():
    topic_name = request.form.get('topic_name', '').strip()
    subject_id = request.form.get('subject_id', '').strip()
    grade = request.form.get('grade', '').strip()
    if not topic_name or not subject_id or not grade:
        flash('Topic name, subject, and grade are required.', 'danger')
        return redirect(url_for('manage_topics'))
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO topics (topic_name, subject_id, grade)
        VALUES (%s, %s, %s)
    """, (topic_name, subject_id, grade))
    conn.commit()
    cur.close(); conn.close()
    flash('Topic added successfully.', 'success')
    return redirect(url_for('manage_topics'))

@app.route('/admin/topics/edit/<int:topic_id>', methods=['POST'])
@admin_required
def edit_topic(topic_id):
    topic_name = request.form.get('topic_name', '').strip()
    subject_id = request.form.get('subject_id', '').strip()
    grade = request.form.get('grade', '').strip()
    if not topic_name or not subject_id or not grade:
        flash('Topic name, subject, and grade are required.', 'danger')
        return redirect(url_for('manage_topics'))
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        UPDATE topics
        SET topic_name = %s, subject_id = %s, grade = %s
        WHERE topic_id = %s
    """, (topic_name, subject_id, grade, topic_id))
    conn.commit()
    cur.close(); conn.close()
    flash('Topic updated successfully.', 'success')
    return redirect(url_for('manage_topics'))

@app.route('/admin/topics/delete/<int:topic_id>')
@admin_required
def delete_topic(topic_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) AS total FROM questions WHERE topic_id = %s", (topic_id,))
    question_count = cur.fetchone()['total']
    if question_count > 0:
        cur.close(); conn.close()
        flash('Cannot delete this topic because it still has questions.', 'danger')
        return redirect(url_for('manage_topics'))
    cur.execute("DELETE FROM topics WHERE topic_id = %s", (topic_id,))
    conn.commit()
    cur.close(); conn.close()
    flash('Topic deleted successfully.', 'success')
    return redirect(url_for('manage_topics'))

@app.route('/admin/questions/add', methods=['POST'])
@admin_required
def add_question():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("""
        INSERT INTO questions
        (topic_id, question_text, option_a, option_b, option_c, option_d, correct_option)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (request.form['topic_id'], request.form['question_text'],
          request.form['option_a'], request.form['option_b'],
          request.form['option_c'], request.form['option_d'],
          request.form['correct_option'].upper()))
    conn.commit()
    cur.close(); conn.close()
    flash('Question added!', 'success')
    return redirect(url_for('manage_questions'))

@app.route('/admin/questions/edit/<int:qid>', methods=['POST'])
@admin_required
def edit_question(qid):
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("""
        UPDATE questions
        SET question_text=%s, option_a=%s, option_b=%s,
            option_c=%s, option_d=%s, correct_option=%s, topic_id=%s
        WHERE question_id=%s
    """, (request.form['question_text'],
          request.form['option_a'], request.form['option_b'],
          request.form['option_c'], request.form['option_d'],
          request.form['correct_option'].upper(),
          request.form['topic_id'], qid))
    conn.commit()
    cur.close(); conn.close()
    flash('Question updated!', 'success')
    return redirect(url_for('manage_questions'))

@app.route('/admin/questions/delete/<int:qid>')
@admin_required
def delete_question(qid):
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("DELETE FROM questions WHERE question_id = %s", (qid,))
    conn.commit()
    cur.close(); conn.close()
    flash('Question deleted.', 'success')
    return redirect(url_for('manage_questions'))

@app.route('/admin/students')
@admin_required
def manage_students():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM students ORDER BY total_points DESC")
    students = cur.fetchall()
    cur.close(); conn.close()
    return render_template('manage_students.html', students=students)

@app.route('/admin/student/<int:student_id>')
@admin_required
def student_activity(student_id):
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM students WHERE student_id = %s", (student_id,))
    student = cur.fetchone()
    cur.execute("SELECT * FROM results WHERE student_id = %s ORDER BY attempted_at DESC",
                (student_id,))
    results = cur.fetchall()
    cur.execute("SELECT * FROM subjects")
    subjects = cur.fetchall()
    subject_progress = []
    for subj in subjects:
        total_topics = count_topics_for_subject_with_grade_fallback(
            cur,
            subj['subject_id'],
            student['grade'],
        )
        cur.execute("""
            SELECT COUNT(DISTINCT topic_name) AS attempted FROM results
            WHERE student_id = %s AND subject_name = %s
        """, (student_id, subj['subject_name']))
        attempted = cur.fetchone()['attempted']
        pct = int((attempted / total_topics * 100)) if total_topics > 0 else 0
        subject_progress.append({
            'subject_name': subj['subject_name'],
            'icon':         subj['icon'],
            'color_class':  subj['color_class'],
            'total_topics': total_topics,
            'attempted':    attempted,
            'pct':          pct
        })
    cur.close(); conn.close()
    return render_template('student_activity.html',
        student=student, results=results, subject_progress=subject_progress)

@app.route('/admin/admins')
@super_admin_required
def manage_admins():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("SELECT * FROM admins ORDER BY is_super_admin DESC")
    admins = cur.fetchall()
    cur.close(); conn.close()
    return render_template('manage_admins.html', admins=admins)

@app.route('/admin/admins/add', methods=['POST'])
@super_admin_required
def add_admin():
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("""
        INSERT INTO admins (username, password_hash, display_name, is_super_admin)
        VALUES (%s, %s, %s, %s)
    """, (request.form['username'].lower(),
          hash_password(request.form['password']),
          request.form['display_name'],
          True if request.form.get('is_super_admin') else False))
    conn.commit()
    cur.close(); conn.close()
    flash('Admin added!', 'success')
    return redirect(url_for('manage_admins'))

@app.route('/admin/admins/delete/<int:aid>')
@super_admin_required
def delete_admin(aid):
    if aid == session['admin_id']:
        flash("You can't delete yourself!", 'danger')
        return redirect(url_for('manage_admins'))
    conn = get_db()
    cur  = conn.cursor()
    cur.execute("DELETE FROM admins WHERE admin_id = %s", (aid,))
    conn.commit()
    cur.close(); conn.close()
    flash('Admin removed.', 'success')
    return redirect(url_for('manage_admins'))


@app.route('/ai-tutor/<tutor_session_id>')
@student_required
def ai_tutor(tutor_session_id):
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT *
        FROM ai_tutor_sessions
        WHERE tutor_session_id = %s AND student_id = %s
    """, (tutor_session_id, session['student_id']))
    tutor_session = cur.fetchone()
    if not tutor_session:
        cur.close()
        conn.close()
        flash('AI Tutor is locked. Finish a quiz to unlock it.', 'warning')
        return redirect(url_for('student_dashboard'))
    cur.execute("""
        SELECT role, message_text, meta_json, created_at
        FROM ai_tutor_messages
        WHERE tutor_session_id = %s
        ORDER BY created_at ASC, message_id ASC
    """, (tutor_session_id,))
    messages = cur.fetchall()
    context = tutor_session['context_json']
    wrong_questions = [q for q in context.get('questions', []) if not q.get('is_correct')]
    cur.close()
    conn.close()
    return render_template(
        'ai_tutor.html',
        tutor_session=tutor_session,
        messages=messages,
        wrong_questions=wrong_questions,
        ai_tutor_locked=False,
        tutor_session_id=tutor_session_id
    )


@app.route('/api/ai-tutor/explain', methods=['POST'])
@student_required
def ai_tutor_explain():
    payload = request.get_json(silent=True) or {}
    tutor_session_id = payload.get('tutor_session_id', '')
    question_id = payload.get('question_id')
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT context_json, topic_name, subject_name
        FROM ai_tutor_sessions
        WHERE tutor_session_id = %s AND student_id = %s
    """, (tutor_session_id, session['student_id']))
    tutor_session = cur.fetchone()
    if not tutor_session:
        cur.close()
        conn.close()
        return jsonify({'error': 'Tutor session not found.'}), 404
    context = tutor_session['context_json']
    selected = None
    for item in context.get('questions', []):
        if int(item.get('question_id', -1)) == int(question_id):
            selected = item
            break
    if not selected:
        cur.close()
        conn.close()
        return jsonify({'error': 'Question not found for this session.'}), 404
    question_text = selected.get('question_text') or "Unknown question"
    student_answer = selected.get('selected_answer') or "No answer given"
    correct_answer = selected.get('correct_answer') or "Unknown"
    explain_prompt = (
        "The student got this question wrong.\n"
        f"Question: {question_text}\n"
        f"Student answered: {student_answer}\n"
        f"Correct answer: {correct_answer}\n"
        "Please explain clearly and simply why the correct answer is right\n"
        "and why the student's answer is wrong. Use simple language for a\n"
        "primary school kid aged 6-12."
    )
    explain_prompt = sanitize_for_gemini_text(explain_prompt)
    # Get history BEFORE saving the new message to avoid duplicate/consecutive user messages
    history = get_tutor_conversation_history(cur, tutor_session_id)
    # Append the explain prompt as the next user turn directly into history list
    history.append({'role': 'user', 'text': explain_prompt})
    topic_name_val = tutor_session.get('topic_name') or context.get('topic') or 'General Studies'
    subject_name_val = tutor_session.get('subject_name') or context.get('subject') or 'General'
    explainer, err = call_gemini_with_history(topic_name_val, subject_name_val, history)
    if err:
        cur.close()
        conn.close()
        return jsonify({'error': err}), 502
    # Save both messages only after successful Gemini response
    save_tutor_message(cur, tutor_session_id, 'user', explain_prompt, {'type': 'question_explain_request', 'question_id': question_id})
    save_tutor_message(cur, tutor_session_id, 'assistant', explainer, {'type': 'question_explanation', 'question_id': question_id, 'provider': 'gemini'})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({'message': explainer})


@app.route('/api/ai-tutor/chat', methods=['POST'])
@student_required
def ai_tutor_chat():
    payload = request.get_json(silent=True) or {}
    tutor_session_id = payload.get('tutor_session_id', '')
    raw_text = payload.get('message', '')
    user_text = sanitize_child_prompt(raw_text)
    if not user_text:
        return jsonify({'error': 'Please type a message first.'}), 400
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT context_json, topic_name, subject_name
        FROM ai_tutor_sessions
        WHERE tutor_session_id = %s AND student_id = %s
    """, (tutor_session_id, session['student_id']))
    tutor_session = cur.fetchone()
    if not tutor_session:
        cur.close()
        conn.close()
        return jsonify({'error': 'Tutor session not found.'}), 404
    history = get_tutor_conversation_history(cur, tutor_session_id)
    history.append({"role": "user", "text": user_text})
    topic_name_val = tutor_session.get("topic_name") or tutor_session["context_json"].get("topic") or "General Studies"
    subject_name_val = tutor_session.get("subject_name") or tutor_session["context_json"].get("subject") or "General"
    ai_response, err = call_gemini_with_history(topic_name_val, subject_name_val, history)
    if err:
        cur.close()
        conn.close()
        return jsonify({"error": err}), 502
    save_tutor_message(cur, tutor_session_id, "user", user_text, {"type": "chat_input"})
    save_tutor_message(cur, tutor_session_id, "assistant", ai_response, {"type": "chat_reply", "provider": "gemini"})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({'message': ai_response})


@app.route('/api/ai-tutor/gemini-chat', methods=['POST'])
@student_required
def ai_tutor_gemini_chat():
    payload = request.get_json(silent=True) or {}
    tutor_session_id = payload.get('tutor_session_id', '')
    user_message = sanitize_child_prompt(payload.get('message', ''))
    conversation_history = payload.get('history', [])
    if not user_message:
        return jsonify({'error': 'Please type a message first.'}), 400
    if not isinstance(conversation_history, list):
        return jsonify({'error': 'Invalid conversation history.'}), 400
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT topic_name, subject_name, context_json
        FROM ai_tutor_sessions
        WHERE tutor_session_id = %s AND student_id = %s
    """, (tutor_session_id, session['student_id']))
    tutor_session = cur.fetchone()
    if not tutor_session:
        cur.close()
        conn.close()
        return jsonify({'error': 'Tutor session not found.'}), 404
    # Fetch history BEFORE saving new message to avoid consecutive user-role turns
    history = get_tutor_conversation_history(cur, tutor_session_id)
    history.append({'role': 'user', 'text': user_message})
    ai_response, err = call_gemini_with_history(
        tutor_session.get('topic_name') or 'General Studies',
        tutor_session.get('subject_name') or 'General',
        history
    )
    if err:
        cur.close()
        conn.close()
        return jsonify({'error': err}), 502
    # Save both only after successful Gemini response
    save_tutor_message(cur, tutor_session_id, 'user', user_message, {'type': 'chat_input'})
    save_tutor_message(cur, tutor_session_id, 'assistant', ai_response, {'type': 'chat_reply', 'provider': 'gemini'})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({'message': ai_response})


@app.route('/api/ai-tutor/redemption/new', methods=['POST'])
@student_required
def ai_tutor_redemption_new():
    payload = request.get_json(silent=True) or {}
    tutor_session_id = payload.get('tutor_session_id', '')
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT topic_name
        FROM ai_tutor_sessions
        WHERE tutor_session_id = %s AND student_id = %s
    """, (tutor_session_id, session['student_id']))
    tutor_session = cur.fetchone()
    if not tutor_session:
        cur.close()
        conn.close()
        return jsonify({'error': 'Tutor session not found.'}), 404
    topic_name_val = tutor_session.get('topic_name') or 'General Studies'
    subject_name_val = tutor_session.get('subject_name') or 'General'
    # Use Gemini to generate a topic-relevant challenge question
    gen_prompt = (
        'Generate one short quiz question for a primary school student (Grade 1-5) '
        'about the topic "' + topic_name_val + '" (Subject: ' + subject_name_val + '). '
        'The question must be clear, simple, and have a single correct short answer '
        '(a word, number, or short phrase). '
        'Respond ONLY with a valid JSON object in this exact format with no extra text or markdown: '
        '{"question": "your question here", "answer": "the answer here"}'
    )
    gemini_history = [{'role': 'user', 'text': gen_prompt}]
    raw_response, gen_err = call_gemini_with_history(topic_name_val, subject_name_val, gemini_history)
    question_text = None
    answer_text = None
    if raw_response and not gen_err:
        try:
            clean = raw_response.strip()
            # Strip markdown code fences if present
            if clean.startswith('```'):
                clean = clean.split('```')[1]
                if clean.startswith('json'):
                    clean = clean[4:]
            clean = clean.strip()
            parsed = json.loads(clean)
            question_text = str(parsed.get('question', '')).strip()
            answer_text = str(parsed.get('answer', '')).strip().lower()
        except Exception:
            app.logger.warning('redemption_parse_failed raw=%s', raw_response[:300])
    if not question_text or not answer_text:
        # Fallback: simple multiplication
        a = random.randint(2, 12)
        b = random.randint(2, 10)
        question_text = 'What is ' + str(a) + ' x ' + str(b) + '?'
        answer_text = str(a * b)
    display_text = 'Level-Up Challenge: ' + question_text
    cur.execute("""
        INSERT INTO ai_tutor_redemptions (tutor_session_id, question_text, answer_text)
        VALUES (%s, %s, %s)
        RETURNING redemption_id
    """, (tutor_session_id, display_text, answer_text))
    redemption = cur.fetchone()
    save_tutor_message(cur, tutor_session_id, 'assistant', display_text, {'type': 'redemption_question', 'redemption_id': redemption['redemption_id']})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({'redemption_id': redemption['redemption_id'], 'question_text': display_text})


@app.route('/api/ai-tutor/redemption/answer', methods=['POST'])
@student_required
def ai_tutor_redemption_answer():
    payload = request.get_json(silent=True) or {}
    tutor_session_id = payload.get('tutor_session_id', '')
    redemption_id = payload.get('redemption_id')
    student_answer = sanitize_child_prompt(str(payload.get('answer', '')))
    conn = get_db()
    ensure_ai_tutor_tables(conn)
    cur = conn.cursor()
    cur.execute("""
        SELECT r.redemption_id, r.answer_text
        FROM ai_tutor_redemptions r
        JOIN ai_tutor_sessions s ON s.tutor_session_id = r.tutor_session_id
        WHERE r.redemption_id = %s AND r.tutor_session_id = %s AND s.student_id = %s
    """, (redemption_id, tutor_session_id, session['student_id']))
    redemption = cur.fetchone()
    if not redemption:
        cur.close()
        conn.close()
        return jsonify({'error': 'Challenge not found.'}), 404
    is_correct = student_answer.strip().lower() == redemption['answer_text'].strip().lower()
    awarded = 2 if is_correct else 0
    cur.execute("""
        UPDATE ai_tutor_redemptions
        SET student_answer = %s, is_correct = %s, awarded_points = %s
        WHERE redemption_id = %s
    """, (student_answer, is_correct, awarded, redemption_id))
    if awarded > 0:
        cur.execute("""
            UPDATE students
            SET total_points = total_points + %s
            WHERE student_id = %s
        """, (awarded, session['student_id']))
        session['total_points'] = session.get('total_points', 0) + awarded
    message = (
        "Great job! You earned back 2 points! 🎉"
        if is_correct
        else f"Nice try! The answer was {redemption['answer_text']}. Let's keep practicing."
    )
    save_tutor_message(cur, tutor_session_id, 'assistant', message, {'type': 'redemption_result', 'awarded_points': awarded})
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({'is_correct': is_correct, 'awarded_points': awarded, 'message': message})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)