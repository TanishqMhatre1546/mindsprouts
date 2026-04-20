from copy import deepcopy

from flask import Blueprint, jsonify, request, session
from psycopg2.extras import Json


def _normalize_subject(subject_name):
    text = (subject_name or "").strip().lower()
    if "math" in text:
        return "maths"
    if "science" in text:
        return "science"
    if text in {"gk", "general knowledge"} or "general" in text:
        return "gk"
    if "english" in text:
        return "english"
    return text


# 20 grade+subject game definitions.
GAME_MANIFEST = {
    (1, "english"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Letter Twins",
            "instruction": "Match each uppercase letter to its lowercase partner.",
            "pairs": [
                {"left": "A", "right": "a"},
                {"left": "B", "right": "b"},
                {"left": "C", "right": "c"},
            ],
        },
    },
    (1, "maths"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Skip Count Sprint",
            "instruction": "Collect numbers in skip counting by 2.",
            "correct_items": ["2", "4", "6", "8"],
            "obstacle_items": ["3", "5", "7"],
        },
    },
    (1, "science"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Baby Animal Match",
            "instruction": "Match each animal to its baby.",
            "pairs": [
                {"left": "Dog", "right": "Puppy"},
                {"left": "Cat", "right": "Kitten"},
                {"left": "Cow", "right": "Calf"},
            ],
        },
    },
    (1, "gk"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Community Helpers",
            "instruction": "Sort each object into the correct helper bin.",
            "bins": ["Police", "Doctor"],
            "items": [
                {"label": "Badge", "answer": "Police"},
                {"label": "Stethoscope", "answer": "Doctor"},
            ],
        },
    },
    (2, "english"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Noun or Verb?",
            "instruction": "Sort each word into Noun or Verb.",
            "bins": ["Noun", "Verb"],
            "items": [
                {"label": "Apple", "answer": "Noun"},
                {"label": "Run", "answer": "Verb"},
                {"label": "London", "answer": "Noun"},
                {"label": "Jump", "answer": "Verb"},
            ],
        },
    },
    (2, "maths"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Shape Sort",
            "instruction": "Drop each shape into 2D or 3D.",
            "bins": ["2D", "3D"],
            "items": [
                {"label": "Circle", "answer": "2D"},
                {"label": "Cube", "answer": "3D"},
                {"label": "Square", "answer": "2D"},
                {"label": "Sphere", "answer": "3D"},
            ],
        },
    },
    (2, "science"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Space Pairs",
            "instruction": "Match space words with their type.",
            "pairs": [
                {"left": "Sun", "right": "Star"},
                {"left": "Earth", "right": "Planet"},
                {"left": "Moon", "right": "Satellite"},
            ],
        },
    },
    (2, "gk"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Animal Homes",
            "instruction": "Sort animals as Domestic or Wild.",
            "bins": ["Domestic", "Wild"],
            "items": [
                {"label": "Dog", "answer": "Domestic"},
                {"label": "Lion", "answer": "Wild"},
                {"label": "Cow", "answer": "Domestic"},
                {"label": "Tiger", "answer": "Wild"},
            ],
        },
    },
    (3, "english"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Prefix Dash",
            "instruction": "Collect words that can take prefix 'Un-'.",
            "correct_items": ["Happy", "Kind", "Able"],
            "obstacle_items": ["Quick", "Blue"],
        },
    },
    (3, "maths"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Times Table Track",
            "instruction": "Catch the product of 4 x 3.",
            "correct_items": ["12"],
            "obstacle_items": ["7", "14", "16"],
        },
    },
    (3, "science"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Plant Parts Run",
            "instruction": "Collect only plant parts.",
            "correct_items": ["Root", "Stem", "Leaf", "Flower"],
            "obstacle_items": ["Rock", "Cloud"],
        },
    },
    (3, "gk"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Flag Color Run",
            "instruction": "Collect the colors of the Indian flag.",
            "correct_items": ["Saffron", "White", "Green"],
            "obstacle_items": ["Yellow", "Blue"],
        },
    },
    (4, "english"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Word Relation Sort",
            "instruction": "Sort each pair into Synonym or Antonym.",
            "bins": ["Synonym", "Antonym"],
            "items": [
                {"label": "Big-Large", "answer": "Synonym"},
                {"label": "Hot-Cold", "answer": "Antonym"},
                {"label": "Quick-Fast", "answer": "Synonym"},
                {"label": "Happy-Sad", "answer": "Antonym"},
            ],
        },
    },
    (4, "maths"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Fraction Match",
            "instruction": "Match fractions with equivalent values.",
            "pairs": [
                {"left": "1/2", "right": "0.5"},
                {"left": "1/4", "right": "0.25"},
                {"left": "3/4", "right": "0.75"},
            ],
        },
    },
    (4, "science"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "States of Matter",
            "instruction": "Sort each item by state of matter.",
            "bins": ["Solid", "Liquid", "Gas"],
            "items": [
                {"label": "Ice", "answer": "Solid"},
                {"label": "Water", "answer": "Liquid"},
                {"label": "Steam", "answer": "Gas"},
            ],
        },
    },
    (4, "gk"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Country & Monuments",
            "instruction": "Match country names to famous monuments.",
            "pairs": [
                {"left": "India", "right": "Taj Mahal"},
                {"left": "France", "right": "Eiffel Tower"},
                {"left": "USA", "right": "Statue of Liberty"},
            ],
        },
    },
    (5, "english"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Part to Whole",
            "instruction": "Match each part with its whole.",
            "pairs": [
                {"left": "Finger", "right": "Hand"},
                {"left": "Toe", "right": "Foot"},
                {"left": "Leaf", "right": "Tree"},
            ],
        },
    },
    (5, "maths"): {
        "game_module": "SORTER",
        "game_data": {
            "title": "Prime Check",
            "instruction": "Sort each number as Prime or Composite.",
            "bins": ["Prime", "Composite"],
            "items": [
                {"label": "7", "answer": "Prime"},
                {"label": "9", "answer": "Composite"},
                {"label": "13", "answer": "Prime"},
                {"label": "15", "answer": "Composite"},
            ],
        },
    },
    (5, "science"): {
        "game_module": "RUNNER",
        "game_data": {
            "title": "Planet Chase",
            "instruction": "Collect only inner planets.",
            "correct_items": ["Mercury", "Venus", "Earth", "Mars"],
            "obstacle_items": ["Jupiter", "Saturn"],
        },
    },
    (5, "gk"): {
        "game_module": "MATCHER",
        "game_data": {
            "title": "Indian Icons",
            "instruction": "Match people with titles.",
            "pairs": [
                {"left": "Mahatma Gandhi", "right": "Father of the Nation"},
                {"left": "Dr APJ Abdul Kalam", "right": "Missile Man"},
                {"left": "Sachin Tendulkar", "right": "Master Blaster"},
            ],
        },
    },
}


def _ensure_games_tables(conn):
    cur = conn.cursor()
    cur.execute(
        """
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'game_module_enum') THEN
                CREATE TYPE game_module_enum AS ENUM ('SORTER', 'RUNNER', 'MATCHER');
            END IF;
        END $$;
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS games (
            game_id SERIAL PRIMARY KEY,
            topic_id INTEGER NOT NULL UNIQUE REFERENCES topics(topic_id) ON DELETE CASCADE,
            game_module game_module_enum NOT NULL,
            game_data JSONB NOT NULL,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        """
    )
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS game_results (
            game_result_id SERIAL PRIMARY KEY,
            game_id INTEGER NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
            topic_id INTEGER NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
            student_id INTEGER NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
            score INTEGER NOT NULL,
            total_items INTEGER NOT NULL,
            accuracy NUMERIC(5,2) NOT NULL,
            time_spent_sec INTEGER NOT NULL,
            points_earned INTEGER NOT NULL DEFAULT 0,
            submitted_payload JSONB,
            attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        );
        """
    )
    conn.commit()
    cur.close()


def _get_topic_context(cur, topic_id):
    cur.execute(
        """
        SELECT t.topic_id, t.topic_name, t.grade, s.subject_name
        FROM topics t
        JOIN subjects s ON s.subject_id = t.subject_id
        WHERE t.topic_id = %s
        """,
        (topic_id,),
    )
    return cur.fetchone()


def _get_or_create_game(cur, topic):
    cur.execute("SELECT game_id, game_module, game_data FROM games WHERE topic_id = %s", (topic["topic_id"],))
    game = cur.fetchone()
    if game:
        return game

    key = (int(topic["grade"]), _normalize_subject(topic["subject_name"]))
    game_template = GAME_MANIFEST.get(key)
    if not game_template:
        return None

    game_copy = deepcopy(game_template)
    cur.execute(
        """
        INSERT INTO games (topic_id, game_module, game_data)
        VALUES (%s, %s, %s)
        ON CONFLICT (topic_id)
        DO UPDATE
        SET game_module = EXCLUDED.game_module,
            game_data = EXCLUDED.game_data,
            updated_at = NOW()
        RETURNING game_id, game_module, game_data
        """,
        (topic["topic_id"], game_copy["game_module"], Json(game_copy["game_data"])),
    )
    return cur.fetchone()


def create_game_blueprint(get_db, student_required):
    game_bp = Blueprint("game_routes", __name__)

    @game_bp.route("/api/topic/<int:topic_id>/mode")
    @student_required
    def topic_mode(topic_id):
        conn = get_db()
        try:
            _ensure_games_tables(conn)
            cur = conn.cursor()
            topic = _get_topic_context(cur, topic_id)
            if not topic:
                cur.close()
                return jsonify({"error": "Topic not found"}), 404
            game = _get_or_create_game(cur, topic)
            conn.commit()
            cur.close()
            if not game:
                return jsonify({"mode": "QUIZ", "topic_id": topic_id}), 200
            return jsonify(
                {
                    "mode": "GAMIFY",
                    "topic_id": topic_id,
                    "game_id": game["game_id"],
                    "game_module": game["game_module"],
                    "game_data": game["game_data"],
                }
            ), 200
        finally:
            conn.close()

    @game_bp.route("/api/game/submit", methods=["POST"])
    @student_required
    def submit_game():
        payload = request.get_json(silent=True) or {}
        topic_id = payload.get("topic_id")
        if topic_id is None:
            return jsonify({"error": "topic_id is required"}), 400

        conn = get_db()
        try:
            _ensure_games_tables(conn)
            cur = conn.cursor()
            topic = _get_topic_context(cur, topic_id)
            if not topic:
                cur.close()
                return jsonify({"error": "Topic not found"}), 404
            game = _get_or_create_game(cur, topic)
            if not game:
                cur.close()
                return jsonify({"error": "No game configured for this topic"}), 400

            raw_score = int(payload.get("score", 0))
            raw_total = int(payload.get("total_items", 1))
            raw_time_spent = int(payload.get("time_spent_sec", 0))

            total_items = max(1, raw_total)
            score = max(0, min(raw_score, total_items))
            time_spent_sec = max(0, raw_time_spent)
            accuracy = round((score / total_items) * 100, 2)
            points_earned = score * 5

            cur.execute(
                """
                INSERT INTO game_results
                (game_id, topic_id, student_id, score, total_items, accuracy, time_spent_sec, points_earned, submitted_payload)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING game_result_id
                """,
                (
                    game["game_id"],
                    topic_id,
                    session["student_id"],
                    score,
                    total_items,
                    accuracy,
                    time_spent_sec,
                    points_earned,
                    Json(payload),
                ),
            )
            game_result = cur.fetchone()
            cur.execute(
                """
                UPDATE students
                SET total_points = total_points + %s
                WHERE student_id = %s
                """,
                (points_earned, session["student_id"]),
            )
            conn.commit()
            cur.close()
            session["total_points"] = session.get("total_points", 0) + points_earned

            return jsonify(
                {
                    "status": "ok",
                    "game_result_id": game_result["game_result_id"],
                    "score": score,
                    "total_items": total_items,
                    "accuracy": accuracy,
                    "time_spent_sec": time_spent_sec,
                    "points_earned": points_earned,
                }
            ), 200
        finally:
            conn.close()

    return game_bp
