-- MindSprouts Gamify schema + seed (20 levels)
-- Run with: psql "$DATABASE_URL" -f sql/games_schema_seed.sql

BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'game_module_enum') THEN
        CREATE TYPE game_module_enum AS ENUM ('SORTER', 'RUNNER', 'MATCHER');
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS games (
    game_id SERIAL PRIMARY KEY,
    topic_id INTEGER NOT NULL UNIQUE REFERENCES topics(topic_id) ON DELETE CASCADE,
    game_module game_module_enum NOT NULL,
    game_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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

WITH manifest AS (
    SELECT *
    FROM (
        VALUES
            (1, 'english', 'MATCHER', '{"title":"Letter Twins","instruction":"Match each uppercase letter to lowercase.","pairs":[{"left":"A","right":"a"},{"left":"B","right":"b"},{"left":"C","right":"c"}]}'),
            (1, 'maths',   'RUNNER',  '{"title":"Skip Count Sprint","instruction":"Collect numbers in skip counting by 2.","correct_items":["2","4","6","8"],"obstacle_items":["3","5","7"]}'),
            (1, 'science', 'MATCHER', '{"title":"Baby Animal Match","instruction":"Match each animal to its baby.","pairs":[{"left":"Dog","right":"Puppy"},{"left":"Cat","right":"Kitten"},{"left":"Cow","right":"Calf"}]}'),
            (1, 'gk',      'SORTER',  '{"title":"Community Helpers","instruction":"Sort each object into helper bins.","bins":["Police","Doctor"],"items":[{"label":"Badge","answer":"Police"},{"label":"Stethoscope","answer":"Doctor"}]}'),
            (2, 'english', 'SORTER',  '{"title":"Noun or Verb?","instruction":"Sort words into Noun or Verb.","bins":["Noun","Verb"],"items":[{"label":"Apple","answer":"Noun"},{"label":"Run","answer":"Verb"},{"label":"London","answer":"Noun"},{"label":"Jump","answer":"Verb"}]}'),
            (2, 'maths',   'SORTER',  '{"title":"Shape Sort","instruction":"Drop each shape into 2D or 3D.","bins":["2D","3D"],"items":[{"label":"Circle","answer":"2D"},{"label":"Cube","answer":"3D"},{"label":"Square","answer":"2D"},{"label":"Sphere","answer":"3D"}]}'),
            (2, 'science', 'MATCHER', '{"title":"Space Pairs","instruction":"Match each object to its type.","pairs":[{"left":"Sun","right":"Star"},{"left":"Earth","right":"Planet"},{"left":"Moon","right":"Satellite"}]}'),
            (2, 'gk',      'SORTER',  '{"title":"Animal Homes","instruction":"Sort animals as Domestic or Wild.","bins":["Domestic","Wild"],"items":[{"label":"Dog","answer":"Domestic"},{"label":"Lion","answer":"Wild"},{"label":"Cow","answer":"Domestic"},{"label":"Tiger","answer":"Wild"}]}'),
            (3, 'english', 'RUNNER',  '{"title":"Prefix Dash","instruction":"Collect words that can take prefix Un-.","correct_items":["Happy","Kind","Able"],"obstacle_items":["Quick","Blue"]}'),
            (3, 'maths',   'RUNNER',  '{"title":"Times Table Track","instruction":"Catch the product of 4 x 3.","correct_items":["12"],"obstacle_items":["7","14","16"]}'),
            (3, 'science', 'RUNNER',  '{"title":"Plant Parts Run","instruction":"Collect only plant parts.","correct_items":["Root","Stem","Leaf","Flower"],"obstacle_items":["Rock","Cloud"]}'),
            (3, 'gk',      'RUNNER',  '{"title":"Flag Color Run","instruction":"Collect colors of Indian flag.","correct_items":["Saffron","White","Green"],"obstacle_items":["Yellow","Blue"]}'),
            (4, 'english', 'SORTER',  '{"title":"Word Relation Sort","instruction":"Sort each pair into Synonym or Antonym.","bins":["Synonym","Antonym"],"items":[{"label":"Big-Large","answer":"Synonym"},{"label":"Hot-Cold","answer":"Antonym"},{"label":"Quick-Fast","answer":"Synonym"},{"label":"Happy-Sad","answer":"Antonym"}]}'),
            (4, 'maths',   'MATCHER', '{"title":"Fraction Match","instruction":"Match fractions with equivalent values.","pairs":[{"left":"1/2","right":"0.5"},{"left":"1/4","right":"0.25"},{"left":"3/4","right":"0.75"}]}'),
            (4, 'science', 'SORTER',  '{"title":"States of Matter","instruction":"Sort by state of matter.","bins":["Solid","Liquid","Gas"],"items":[{"label":"Ice","answer":"Solid"},{"label":"Water","answer":"Liquid"},{"label":"Steam","answer":"Gas"}]}'),
            (4, 'gk',      'MATCHER', '{"title":"Country and Monuments","instruction":"Match country to monument.","pairs":[{"left":"India","right":"Taj Mahal"},{"left":"France","right":"Eiffel Tower"},{"left":"USA","right":"Statue of Liberty"}]}'),
            (5, 'english', 'MATCHER', '{"title":"Part to Whole","instruction":"Match each part to its whole.","pairs":[{"left":"Finger","right":"Hand"},{"left":"Toe","right":"Foot"},{"left":"Leaf","right":"Tree"}]}'),
            (5, 'maths',   'SORTER',  '{"title":"Prime Check","instruction":"Sort number as Prime or Composite.","bins":["Prime","Composite"],"items":[{"label":"7","answer":"Prime"},{"label":"9","answer":"Composite"},{"label":"13","answer":"Prime"},{"label":"15","answer":"Composite"}]}'),
            (5, 'science', 'RUNNER',  '{"title":"Planet Chase","instruction":"Collect only inner planets.","correct_items":["Mercury","Venus","Earth","Mars"],"obstacle_items":["Jupiter","Saturn"]}'),
            (5, 'gk',      'MATCHER', '{"title":"Indian Icons","instruction":"Match person with title.","pairs":[{"left":"Mahatma Gandhi","right":"Father of the Nation"},{"left":"Dr APJ Abdul Kalam","right":"Missile Man"},{"left":"Sachin Tendulkar","right":"Master Blaster"}]}')
    ) AS x(grade, subject_key, game_module, game_data)
),
topic_pool AS (
    SELECT
        t.topic_id,
        t.grade,
        CASE
            WHEN LOWER(s.subject_name) LIKE '%math%' THEN 'maths'
            WHEN LOWER(s.subject_name) LIKE '%science%' THEN 'science'
            WHEN LOWER(s.subject_name) LIKE '%english%' THEN 'english'
            WHEN LOWER(s.subject_name) = 'gk' OR LOWER(s.subject_name) LIKE '%general%' THEN 'gk'
            ELSE LOWER(s.subject_name)
        END AS subject_key,
        ROW_NUMBER() OVER (
            PARTITION BY t.grade,
            CASE
                WHEN LOWER(s.subject_name) LIKE '%math%' THEN 'maths'
                WHEN LOWER(s.subject_name) LIKE '%science%' THEN 'science'
                WHEN LOWER(s.subject_name) LIKE '%english%' THEN 'english'
                WHEN LOWER(s.subject_name) = 'gk' OR LOWER(s.subject_name) LIKE '%general%' THEN 'gk'
                ELSE LOWER(s.subject_name)
            END
            ORDER BY t.topic_id
        ) AS rn
    FROM topics t
    JOIN subjects s ON s.subject_id = t.subject_id
),
selected_topics AS (
    SELECT m.grade, m.subject_key, m.game_module, m.game_data::jsonb, tp.topic_id
    FROM manifest m
    JOIN topic_pool tp
      ON tp.grade = m.grade
     AND tp.subject_key = m.subject_key
     AND tp.rn = 1
)
INSERT INTO games (topic_id, game_module, game_data)
SELECT topic_id, game_module::game_module_enum, game_data
FROM selected_topics
ON CONFLICT (topic_id) DO UPDATE
SET game_module = EXCLUDED.game_module,
    game_data = EXCLUDED.game_data,
    updated_at = NOW();

COMMIT;
