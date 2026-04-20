from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
import psycopg2.extras
import hashlib
import random
from datetime import date
import os
import logging
import uuid
import time
from dotenv import load_dotenv
from game_routes import create_game_blueprint

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
    # Prefer Render's DATABASE_URL if available.
    database_url = os.environ.get('DATABASE_URL')
    if database_url:
        return psycopg2.connect(database_url, cursor_factory=psycopg2.extras.RealDictCursor)

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

    return psycopg2.connect(
        host=pg_host,
        user=pg_user,
        password=pg_password,
        dbname=pg_database,
        port=pg_port,
        cursor_factory=psycopg2.extras.RealDictCursor,
    )

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

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


app.register_blueprint(create_game_blueprint(get_db, student_required))

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
def index():
    if 'student_id' in session:
        return redirect(url_for('student_dashboard'))
    if 'admin_id' in session:
        return redirect(url_for('admin_dashboard'))
    return render_template('index.html')

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
    return render_template('student_dash.html', subjects=subjects, total_quizzes=total_quizzes)

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
    return render_template('topics.html', subject=subject, topics=topics, attempted=attempted)


@app.route('/topic/<int:topic_id>/mode')
@student_required
def topic_mode_page(topic_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM topics WHERE topic_id = %s", (topic_id,))
    topic = cur.fetchone()
    if not topic:
        cur.close(); conn.close()
        flash('Topic not found.', 'danger')
        return redirect(url_for('student_dashboard'))
    cur.execute("SELECT * FROM subjects WHERE subject_id = %s", (topic['subject_id'],))
    subject = cur.fetchone()
    cur.close(); conn.close()
    return render_template('topic_mode.html', topic=topic, subject=subject)


@app.route('/game/<int:topic_id>')
@student_required
def play_game(topic_id):
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM topics WHERE topic_id = %s", (topic_id,))
    topic = cur.fetchone()
    if not topic:
        cur.close(); conn.close()
        flash('Topic not found.', 'danger')
        return redirect(url_for('student_dashboard'))
    cur.execute("SELECT * FROM subjects WHERE subject_id = %s", (topic['subject_id'],))
    subject = cur.fetchone()
    cur.close(); conn.close()
    return render_template('game_play.html', topic=topic, subject=subject)

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
    """, (session['student_id'], session['display_name'],
          subject_name, topic_name, session['grade'], score, total))
    cur.execute("""
        UPDATE students
        SET total_points   = total_points + %s,
            current_streak = %s,
            longest_streak = %s,
            last_quiz_date = %s
        WHERE student_id = %s
    """, (points_earned, current_streak, longest_streak, today, session['student_id']))
    conn.commit()
    cur.close(); conn.close()
    session['total_points']   = session.get('total_points', 0) + points_earned
    session['current_streak'] = current_streak
    session['longest_streak'] = longest_streak
    session.pop('quiz_total_time_sec', None)
    session.pop('quiz_started_at', None)
    session.pop('quiz_failed', None)
    return render_template('result.html',
        score=score, total=total,
        points_earned=points_earned,
        topic_name=topic_name,
        subject_name=subject_name,
        review=review,
        current_streak=current_streak)

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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)