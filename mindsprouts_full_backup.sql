--
-- PostgreSQL database dump
--

\restrict tu7XTUaOZYFonrTE788UGJabKkFheE1631k92KjO85bM6JOXSVCpYbe1kbUjRvV

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg12+1)
-- Dumped by pg_dump version 18.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: mindsprouts_user
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO mindsprouts_user;

--
-- Name: railway; Type: SCHEMA; Schema: -; Owner: mindsprouts_user
--

CREATE SCHEMA railway;


ALTER SCHEMA railway OWNER TO mindsprouts_user;

--
-- Name: game_module_enum; Type: TYPE; Schema: public; Owner: mindsprouts_user
--

CREATE TYPE public.game_module_enum AS ENUM (
    'SORTER',
    'RUNNER',
    'MATCHER'
);


ALTER TYPE public.game_module_enum OWNER TO mindsprouts_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: mindsprouts_user
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value text NOT NULL
);


ALTER TABLE public.app_settings OWNER TO mindsprouts_user;

--
-- Name: game_results; Type: TABLE; Schema: public; Owner: mindsprouts_user
--

CREATE TABLE public.game_results (
    game_result_id integer NOT NULL,
    game_id integer NOT NULL,
    topic_id integer NOT NULL,
    student_id integer NOT NULL,
    score integer NOT NULL,
    total_items integer NOT NULL,
    accuracy numeric(5,2) NOT NULL,
    time_spent_sec integer NOT NULL,
    points_earned integer DEFAULT 0 NOT NULL,
    submitted_payload jsonb,
    attempted_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.game_results OWNER TO mindsprouts_user;

--
-- Name: game_results_game_result_id_seq; Type: SEQUENCE; Schema: public; Owner: mindsprouts_user
--

CREATE SEQUENCE public.game_results_game_result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.game_results_game_result_id_seq OWNER TO mindsprouts_user;

--
-- Name: game_results_game_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mindsprouts_user
--

ALTER SEQUENCE public.game_results_game_result_id_seq OWNED BY public.game_results.game_result_id;


--
-- Name: games; Type: TABLE; Schema: public; Owner: mindsprouts_user
--

CREATE TABLE public.games (
    game_id integer NOT NULL,
    topic_id integer NOT NULL,
    game_module public.game_module_enum NOT NULL,
    game_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.games OWNER TO mindsprouts_user;

--
-- Name: games_game_id_seq; Type: SEQUENCE; Schema: public; Owner: mindsprouts_user
--

CREATE SEQUENCE public.games_game_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.games_game_id_seq OWNER TO mindsprouts_user;

--
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mindsprouts_user
--

ALTER SEQUENCE public.games_game_id_seq OWNED BY public.games.game_id;


--
-- Name: admins; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.admins (
    admin_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    display_name character varying(100) NOT NULL,
    is_super_admin boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.admins OWNER TO mindsprouts_user;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.admins_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.admins_admin_id_seq OWNER TO mindsprouts_user;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.admins_admin_id_seq OWNED BY railway.admins.admin_id;


--
-- Name: questions; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.questions (
    question_id integer NOT NULL,
    topic_id integer NOT NULL,
    question_text text NOT NULL,
    option_a character varying(255) NOT NULL,
    option_b character varying(255) NOT NULL,
    option_c character varying(255) NOT NULL,
    option_d character varying(255) NOT NULL,
    correct_option character(1) NOT NULL
);


ALTER TABLE railway.questions OWNER TO mindsprouts_user;

--
-- Name: questions_question_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.questions_question_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.questions_question_id_seq OWNER TO mindsprouts_user;

--
-- Name: questions_question_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.questions_question_id_seq OWNED BY railway.questions.question_id;


--
-- Name: results; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.results (
    result_id integer NOT NULL,
    student_id integer NOT NULL,
    student_name character varying(100) NOT NULL,
    subject_name character varying(100) NOT NULL,
    topic_name character varying(150) NOT NULL,
    grade integer NOT NULL,
    score integer NOT NULL,
    total_questions integer NOT NULL,
    attempted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.results OWNER TO mindsprouts_user;

--
-- Name: results_result_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.results_result_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.results_result_id_seq OWNER TO mindsprouts_user;

--
-- Name: results_result_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.results_result_id_seq OWNED BY railway.results.result_id;


--
-- Name: students; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.students (
    student_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    display_name character varying(100) NOT NULL,
    grade integer NOT NULL,
    total_points integer DEFAULT 0,
    current_streak integer DEFAULT 0,
    longest_streak integer DEFAULT 0,
    last_quiz_date date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.students OWNER TO mindsprouts_user;

--
-- Name: students_student_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.students_student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.students_student_id_seq OWNER TO mindsprouts_user;

--
-- Name: students_student_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.students_student_id_seq OWNED BY railway.students.student_id;


--
-- Name: subjects; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.subjects (
    subject_id integer NOT NULL,
    subject_name character varying(100) NOT NULL,
    icon character varying(50) NOT NULL,
    color_class character varying(50) NOT NULL
);


ALTER TABLE railway.subjects OWNER TO mindsprouts_user;

--
-- Name: subjects_subject_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.subjects_subject_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.subjects_subject_id_seq OWNER TO mindsprouts_user;

--
-- Name: subjects_subject_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.subjects_subject_id_seq OWNED BY railway.subjects.subject_id;


--
-- Name: topics; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE railway.topics (
    topic_id integer NOT NULL,
    subject_id integer NOT NULL,
    topic_name character varying(150) NOT NULL,
    grade integer NOT NULL
);


ALTER TABLE railway.topics OWNER TO mindsprouts_user;

--
-- Name: topics_topic_id_seq; Type: SEQUENCE; Schema: railway; Owner: mindsprouts_user
--

CREATE SEQUENCE railway.topics_topic_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE railway.topics_topic_id_seq OWNER TO mindsprouts_user;

--
-- Name: topics_topic_id_seq; Type: SEQUENCE OWNED BY; Schema: railway; Owner: mindsprouts_user
--

ALTER SEQUENCE railway.topics_topic_id_seq OWNED BY railway.topics.topic_id;


--
-- Name: game_results game_result_id; Type: DEFAULT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.game_results ALTER COLUMN game_result_id SET DEFAULT nextval('public.game_results_game_result_id_seq'::regclass);


--
-- Name: games game_id; Type: DEFAULT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.games ALTER COLUMN game_id SET DEFAULT nextval('public.games_game_id_seq'::regclass);


--
-- Name: admins admin_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.admins ALTER COLUMN admin_id SET DEFAULT nextval('railway.admins_admin_id_seq'::regclass);


--
-- Name: questions question_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.questions ALTER COLUMN question_id SET DEFAULT nextval('railway.questions_question_id_seq'::regclass);


--
-- Name: results result_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.results ALTER COLUMN result_id SET DEFAULT nextval('railway.results_result_id_seq'::regclass);


--
-- Name: students student_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.students ALTER COLUMN student_id SET DEFAULT nextval('railway.students_student_id_seq'::regclass);


--
-- Name: subjects subject_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.subjects ALTER COLUMN subject_id SET DEFAULT nextval('railway.subjects_subject_id_seq'::regclass);


--
-- Name: topics topic_id; Type: DEFAULT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.topics ALTER COLUMN topic_id SET DEFAULT nextval('railway.topics_topic_id_seq'::regclass);


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: mindsprouts_user
--

COPY public.app_settings (key, value) FROM stdin;
\.


--
-- Data for Name: game_results; Type: TABLE DATA; Schema: public; Owner: mindsprouts_user
--

COPY public.game_results (game_result_id, game_id, topic_id, student_id, score, total_items, accuracy, time_spent_sec, points_earned, submitted_payload, attempted_at) FROM stdin;
\.


--
-- Data for Name: games; Type: TABLE DATA; Schema: public; Owner: mindsprouts_user
--

COPY public.games (game_id, topic_id, game_module, game_data, created_at, updated_at) FROM stdin;
1	19	MATCHER	{"pairs": [{"left": "1/2", "right": "0.5"}, {"left": "1/4", "right": "0.25"}, {"left": "3/4", "right": "0.75"}], "title": "Fraction Match", "instruction": "Match fractions with equivalent values."}	2026-04-20 10:28:37.833996+00	2026-04-20 10:28:37.833996+00
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.admins (admin_id, username, password_hash, display_name, is_super_admin, created_at) FROM stdin;
1	superadmin	4e4c56e4a15f89f05c2f4c72613da2a18c9665d4f0d6acce16415eb06f9be776	Super Admin	t	2026-04-04 07:17:30+00
3	simran	7d5e1f36606e5f1a693b9d9c822791321b556026b321a8cda2848f38312fb9da	Simran More	f	2026-04-20 11:06:59.117132+00
\.


--
-- Data for Name: questions; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.questions (question_id, topic_id, question_text, option_a, option_b, option_c, option_d, correct_option) FROM stdin;
3945	27	Which word rhymes with NIGHT?	light	dark	sleep	moon	A
3946	27	Which word rhymes with BALL?	tall	bat	bed	leaf	A
3947	27	Which word rhymes with RAIN?	train	cloud	bird	sand	A
3948	27	Which word rhymes with STAR?	car	tree	pen	cat	A
3969	30	A complete sentence has:	Only a noun	Subject and verb	Only punctuation	Only adjective	B
3970	30	Which is a complete sentence?	The red ball	She runs fast.	Running quickly	In the park	B
3971	30	A question sentence ends with:	.	,	?	!	C
3972	30	A command sentence is called:	Declarative	Interrogative	Imperative	Exclamatory	C
3973	30	Every sentence should begin with:	small letter	capital letter	number	symbol	B
3974	30	Which is NOT a complete sentence?	The cat sleeps.	Birds fly.	Under the tree	I am happy.	C
3975	30	A statement sentence:	Asks	Tells information	Shows command only	Always shouts	B
3976	30	Which has correct punctuation?	where are you	Where are you?	where are you?	Where are you	B
3977	30	Subject tells:	What sentence is about	Action only	Punctuation	Nothing	A
3978	30	Verb tells:	Action/state	Color	Place	Person only	A
3989	32	A complete sentence has:	Only a noun	Subject and verb	Only punctuation	Only adjective	B
3990	32	Which is a complete sentence?	The red ball	She runs fast.	Running quickly	In the park	B
3991	32	A question sentence ends with:	.	,	?	!	C
3992	32	A command sentence is called:	Declarative	Interrogative	Imperative	Exclamatory	C
3993	32	Every sentence should begin with:	small letter	capital letter	number	symbol	B
3994	32	Which is NOT a complete sentence?	The cat sleeps.	Birds fly.	Under the tree	I am happy.	C
3995	32	A statement sentence:	Asks	Tells information	Shows command only	Always shouts	B
3996	32	Which has correct punctuation?	where are you	Where are you?	where are you?	Where are you	B
3997	32	Subject tells:	What sentence is about	Action only	Punctuation	Nothing	A
3998	32	Verb tells:	Action/state	Color	Place	Person only	A
3999	33	Choose correct: He ___ to school.	go	goes	going	gone	B
4000	33	Choose correct: They ___ happy.	is	are	am	was	B
4001	33	Plural of child is:	childs	children	childes	childer	B
4002	33	Use 'an' before:	vowel sound	consonant sound	any word	plural only	A
4003	33	Use 'a' before:	vowel sound	consonant sound	silent words only	plural only	B
4004	33	Choose correct: I ___ a student.	is	are	am	be	C
4005	33	Opposite of 'big' is:	large	small	huge	tall	B
4006	33	Choose conjunction:	run	and	happy	table	B
4007	33	Choose pronoun:	Ravi	he	book	blue	B
4008	33	Choose article:	on	the	run	quick	B
4059	39	Choose correct: He ___ to school.	go	goes	going	gone	B
4060	39	Choose correct: They ___ happy.	is	are	am	was	B
4061	39	Plural of child is:	childs	children	childes	childer	B
4062	39	Use 'an' before:	vowel sound	consonant sound	any word	plural only	A
4063	39	Use 'a' before:	vowel sound	consonant sound	silent words only	plural only	B
4064	39	Choose correct: I ___ a student.	is	are	am	be	C
4065	39	Opposite of 'big' is:	large	small	huge	tall	B
4066	39	Choose conjunction:	run	and	happy	table	B
4067	39	Choose pronoun:	Ravi	he	book	blue	B
4068	39	Choose article:	on	the	run	quick	B
4029	36	Main idea means:	Small detail	Central point	Last line	Title only	B
4030	36	A summary should include:	Every detail	Main points	Only examples	Only title	B
4031	36	Context clues help us:	Skip words	Guess meaning of unknown words	Read slowly	Count words	B
4032	36	Theme of story is:	Setting	Message	Character name	Page number	B
4033	36	Inference means:	Copy text	Understand implied meaning	Read aloud	Memorize	B
4034	36	A fact is:	Opinion	Verifiable statement	Feeling	Guess	B
4035	36	Point of view is:	Color of page	Narrator perspective	Chapter length	Font size	B
4036	36	Skimming is used to:	Read every word deeply	Get quick overall idea	Memorize	Translate	B
4037	36	Scanning is used to:	Find specific information	Read story aloud	Write summary	Draw charts	A
4038	36	A supporting detail:	Changes topic	Explains main idea	Ends paragraph only	Gives title	B
4099	43	Choose correct: He ___ to school.	go	goes	going	gone	B
4100	43	Choose correct: They ___ happy.	is	are	am	was	B
4101	43	Plural of child is:	childs	children	childes	childer	B
4102	43	Use 'an' before:	vowel sound	consonant sound	any word	plural only	A
4103	43	Use 'a' before:	vowel sound	consonant sound	silent words only	plural only	B
4104	43	Choose correct: I ___ a student.	is	are	am	be	C
4105	43	Opposite of 'big' is:	large	small	huge	tall	B
4106	43	Choose conjunction:	run	and	happy	table	B
4107	43	Choose pronoun:	Ravi	he	book	blue	B
4108	43	Choose article:	on	the	run	quick	B
4089	42	First step before writing:	Publish	Plan ideas	Skip to conclusion	Use difficult words	B
4090	42	Introduction should:	Be empty	Grab reader attention	Repeat conclusion	Be unrelated	B
4091	42	A paragraph should contain:	One main idea	Many random ideas	Only one word	No punctuation	A
4092	42	Proofreading means:	Checking for mistakes	Adding drawings	Writing first draft	Ignoring grammar	A
4093	42	Narrative writing tells:	A story	Only facts	Only rules	Only numbers	A
4094	42	Conclusion should:	Introduce topic	Summarize and close	Add unrelated point	Stay unfinished	B
4095	42	Good writing has:	Clear ideas	No punctuation	No structure	Only long sentences	A
4096	42	Dialogue is:	Conversation in writing	Heading	List	Math formula	A
4097	42	Conflict in story means:	Problem/struggle	Title	Setting	Author name	A
4098	42	Revision means:	Improve draft	Delete whole text	Copy others	Stop writing	A
4119	45	Main idea means:	Small detail	Central point	Last line	Title only	B
4120	45	A summary should include:	Every detail	Main points	Only examples	Only title	B
4121	45	Context clues help us:	Skip words	Guess meaning of unknown words	Read slowly	Count words	B
4122	45	Theme of story is:	Setting	Message	Character name	Page number	B
4123	45	Inference means:	Copy text	Understand implied meaning	Read aloud	Memorize	B
4124	45	A fact is:	Opinion	Verifiable statement	Feeling	Guess	B
4125	45	Point of view is:	Color of page	Narrator perspective	Chapter length	Font size	B
4126	45	Skimming is used to:	Read every word deeply	Get quick overall idea	Memorize	Translate	B
4127	45	Scanning is used to:	Find specific information	Read story aloud	Write summary	Draw charts	A
4128	45	A supporting detail:	Changes topic	Explains main idea	Ends paragraph only	Gives title	B
4139	47	Main idea means:	Small detail	Central point	Last line	Title only	B
4140	47	A summary should include:	Every detail	Main points	Only examples	Only title	B
4141	47	Context clues help us:	Skip words	Guess meaning of unknown words	Read slowly	Count words	B
4142	47	Theme of story is:	Setting	Message	Character name	Page number	B
4143	47	Inference means:	Copy text	Understand implied meaning	Read aloud	Memorize	B
4144	47	A fact is:	Opinion	Verifiable statement	Feeling	Guess	B
4145	47	Point of view is:	Color of page	Narrator perspective	Chapter length	Font size	B
4146	47	Skimming is used to:	Read every word deeply	Get quick overall idea	Memorize	Translate	B
4147	47	Scanning is used to:	Find specific information	Read story aloud	Write summary	Draw charts	A
4148	47	A supporting detail:	Changes topic	Explains main idea	Ends paragraph only	Gives title	B
4149	48	First step before writing:	Publish	Plan ideas	Skip to conclusion	Use difficult words	B
4359	69	Which organ pumps blood?	Lungs	Heart	Brain	Stomach	B
4360	69	Which part helps us breathe?	Liver	Lungs	Kidneys	Skin	B
4361	69	How many eyes does a person have?	1	2	3	4	B
4362	69	Which part helps us smell?	Ears	Nose	Tongue	Eyes	B
4363	69	Which part helps us hear?	Eyes	Nose	Ears	Hands	C
4364	69	What protects our brain?	Skull	Ribs	Teeth	Nails	A
4365	69	How many legs do humans have?	1	2	3	4	B
4366	69	Which body part tastes food?	Tongue	Nose	Ear	Hand	A
4367	69	Bones give our body?	Color	Shape and support	Food	Water	B
4368	69	Which sense organ sees?	Eyes	Ears	Nose	Skin	A
4150	48	Introduction should:	Be empty	Grab reader attention	Repeat conclusion	Be unrelated	B
4151	48	A paragraph should contain:	One main idea	Many random ideas	Only one word	No punctuation	A
4152	48	Proofreading means:	Checking for mistakes	Adding drawings	Writing first draft	Ignoring grammar	A
4153	48	Narrative writing tells:	A story	Only facts	Only rules	Only numbers	A
4154	48	Conclusion should:	Introduce topic	Summarize and close	Add unrelated point	Stay unfinished	B
4155	48	Good writing has:	Clear ideas	No punctuation	No structure	Only long sentences	A
4156	48	Dialogue is:	Conversation in writing	Heading	List	Math formula	A
4157	48	Conflict in story means:	Problem/struggle	Title	Setting	Author name	A
4158	48	Revision means:	Improve draft	Delete whole text	Copy others	Stop writing	A
4169	50	Main idea means:	Small detail	Central point	Last line	Title only	B
4170	50	A summary should include:	Every detail	Main points	Only examples	Only title	B
4171	50	Context clues help us:	Skip words	Guess meaning of unknown words	Read slowly	Count words	B
4172	50	Theme of story is:	Setting	Message	Character name	Page number	B
4173	50	Inference means:	Copy text	Understand implied meaning	Read aloud	Memorize	B
4174	50	A fact is:	Opinion	Verifiable statement	Feeling	Guess	B
4175	50	Point of view is:	Color of page	Narrator perspective	Chapter length	Font size	B
4176	50	Skimming is used to:	Read every word deeply	Get quick overall idea	Memorize	Translate	B
4177	50	Scanning is used to:	Find specific information	Read story aloud	Write summary	Draw charts	A
4178	50	A supporting detail:	Changes topic	Explains main idea	Ends paragraph only	Gives title	B
4159	49	First step before writing:	Publish	Plan ideas	Skip to conclusion	Use difficult words	B
4160	49	Introduction should:	Be empty	Grab reader attention	Repeat conclusion	Be unrelated	B
4161	49	A paragraph should contain:	One main idea	Many random ideas	Only one word	No punctuation	A
4162	49	Proofreading means:	Checking for mistakes	Adding drawings	Writing first draft	Ignoring grammar	A
4163	49	Narrative writing tells:	A story	Only facts	Only rules	Only numbers	A
4164	49	Conclusion should:	Introduce topic	Summarize and close	Add unrelated point	Stay unfinished	B
4165	49	Good writing has:	Clear ideas	No punctuation	No structure	Only long sentences	A
4166	49	Dialogue is:	Conversation in writing	Heading	List	Math formula	A
4167	49	Conflict in story means:	Problem/struggle	Title	Setting	Author name	A
4168	49	Revision means:	Improve draft	Delete whole text	Copy others	Stop writing	A
4129	46	'As brave as a lion' is:	Metaphor	Simile	Hyperbole	Alliteration	B
4130	46	'I am so hungry I could eat a horse' is:	Hyperbole	Simile	Personification	Oxymoron	A
4131	46	'The wind whispered' is:	Personification	Metaphor	Onomatopoeia	Literal	A
4132	46	Alliteration means:	Similar vowel sounds	Repetition of starting consonant sounds	Opposite words	Question style	B
4133	46	'Life is a journey' is:	Simile	Metaphor	Hyperbole	Pun	B
4134	46	'Deafening silence' is:	Oxymoron	Simile	Metaphor	Alliteration	A
4135	46	Onomatopoeia words imitate:	Colors	Sounds	Shapes	Numbers	B
4136	46	'buzz', 'hiss' are:	Adjectives	Onomatopoeia	Pronouns	Prepositions	B
4137	46	Simile uses words:	and/but	like/as	because/if	to/from	B
4138	46	Personification gives human qualities to:	Only people	Objects/animals	Only verbs	Numbers	B
4430	76	What sound does a cat make?	Bark	Meow	Moo	Roar	B
4431	76	What sound does a cow make?	Moo	Quack	Hiss	Buzz	A
4432	76	What sound does a duck make?	Roar	Quack	Moo	Neigh	B
4433	76	What sound does a lion make?	Moo	Roar	Bark	Hiss	B
4434	76	What sound does a sheep make?	Baa	Bark	Meow	Roar	A
4435	76	What sound does a horse make?	Neigh	Moo	Roar	Hiss	A
4436	76	What sound does a frog make?	Croak	Buzz	Tweet	Roar	A
4437	76	What sound does a snake make?	Hiss	Bark	Moo	Roar	A
4438	76	What sound does a bird make?	Tweet	Moo	Bark	Roar	A
4459	79	What color is the sky on a clear day?	Blue	Green	Pink	Brown	A
4460	79	What color is grass?	Red	Blue	Green	Purple	C
4461	79	What color is a ripe banana?	Blue	Yellow	Black	Pink	B
4462	79	Mix red and yellow gives:	Green	Purple	Orange	Blue	C
4463	79	Mix blue and yellow gives:	Green	Orange	Purple	Brown	A
4464	79	Which is a primary color?	Green	Orange	Blue	Brown	C
4465	79	Stop signal color is:	Green	Yellow	Red	Blue	C
4466	79	Which object is usually white?	Coal	Milk	Leaf	Soil	B
4467	79	Rainbow has how many colors?	5	6	7	8	C
4468	79	Color of sun in a drawing is often:	Black	Yellow	Purple	Brown	B
4469	80	A good habit is:	Wasting food	Brushing teeth daily	Littering	Sleeping late daily	B
4470	80	Before eating we should:	Play games	Wash hands	Watch TV	Run	B
4471	80	At school we should:	Shout loudly	Be respectful	Fight	Break rules	B
4472	80	Good habit at home:	Keep room clean	Throw waste on floor	Ignore elders	Waste water	A
4473	80	When someone speaks, we should:	Interrupt	Listen politely	Shout	Walk away	B
4474	80	Healthy habit:	Eat junk daily	Drink enough water	Skip sleep	Never exercise	B
4475	80	To keep environment clean we should:	Litter	Use dustbin	Burn plastic	Spit anywhere	B
4476	80	Good digital habit:	Share passwords	Use safe passwords	Click unknown links	Talk to strangers online	B
4477	80	When crossing road, we should:	Run blindly	Look both sides	Use phone	Close eyes	B
4478	80	Good teamwork means:	Helping others	Bullying	Ignoring friends	Cheating	A
4509	84	Who treats sick people?	Teacher	Doctor	Farmer	Pilot	B
4510	84	Who teaches students?	Nurse	Teacher	Police	Chef	B
4511	84	Who catches thieves?	Police officer	Doctor	Engineer	Driver	A
4512	84	Who puts out fires?	Pilot	Firefighter	Dentist	Farmer	B
4513	84	Who delivers letters/parcels?	Postman	Chef	Pilot	Judge	A
4514	84	Who grows crops?	Farmer	Teacher	Doctor	Nurse	A
4515	84	Who repairs electric wiring?	Electrician	Pilot	Chef	Tailor	A
4516	84	Who builds houses?	Carpenter/builder	Doctor	Lawyer	Nurse	A
4517	84	Who helps in a library?	Librarian	Driver	Firefighter	Singer	A
4518	84	Who flies an airplane?	Pilot	Mechanic	Teacher	Farmer	A
4569	90	Who invented the telephone?	Edison	Graham Bell	Newton	Tesla	B
4570	90	Who invented the bulb (practical use)?	Edison	Einstein	Darwin	Pasteur	A
4571	90	WWW stands for:	World Wide Web	Wide World Web	World Web Way	Web World Wide	A
4572	90	CPU is:	Central Processing Unit	Computer Power Unit	Central Program Utility	Control Program Unit	A
4573	90	Internet of Things means:	Only websites	Connected smart devices	Only phones	Only computers	B
4574	90	Cloud storage means data stored:	Only on USB	On internet servers	In notebook	In RAM only	B
4575	90	A computer virus is:	Helpful app	Malicious software	Hardware cable	Printer ink	B
4576	90	URL is used for:	Typing essays	Web address	Charging battery	Playing music only	B
4577	90	AI means:	Artificial Intelligence	Automatic Internet	Applied Interface	Advanced Input	A
4578	90	Safe online habit:	Share OTP	Use strong password	Click unknown links	Talk to strangers	B
4560	89	Planet known as Red Planet:	Mercury	Mars	Saturn	Neptune	B
4561	89	Earth takes around __ days around Sun.	200	300	365	500	C
4562	89	Our natural satellite is:	Sun	Moon	Mars	Venus	B
4563	89	Smallest continent:	Europe	Australia	Antarctica	South America	B
4564	89	Largest ocean:	Indian	Atlantic	Pacific	Arctic	C
4565	89	A globe represents:	Only India	Earth	Moon	Weather	B
4566	89	Direction where sun rises:	West	East	North	South	B
4567	89	How many continents are there?	5	6	7	8	C
4568	89	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4619	95	Who is called Father of the Nation (India)?	Nehru	Gandhi	Patel	Bose	B
4620	95	Who was first PM of India?	Nehru	Gandhi	Patel	Shastri	A
4621	95	Independence Day is on:	26 Jan	15 Aug	2 Oct	14 Nov	B
4622	95	Republic Day is on:	26 Jan	15 Aug	2 Oct	1 May	A
4623	95	Who gave 'Jai Hind' slogan famously?	Tagore	Subhas Chandra Bose	Nehru	Bhagat Singh	B
4624	95	Salt March was led by:	Nehru	Gandhi	Patel	Tilak	B
4625	95	Who wrote national anthem?	Tagore	Bankim	Nehru	Kalam	A
4626	95	Who was first woman PM of India?	Pratibha Patil	Indira Gandhi	Sarojini Naidu	Sonia Gandhi	B
4627	95	Quit India Movement year:	1942	1930	1919	1947	A
4628	95	India became independent in:	1942	1945	1947	1950	C
3810	14	Which is greater?	0.7	0.5	Equal	Cannot compare	A
3812	14	1.2 + 0.3 =	1.3	1.4	1.5	1.6	C
3813	14	2.0 - 0.7 =	1.1	1.2	1.3	1.4	C
3814	14	Place value in 3.45 for 4 is:	Ones	Tenths	Hundredths	Thousands	B
3815	14	0.09 has 9 in:	Tenths	Hundredths	Ones	Thousands	B
3816	14	Convert 1/10 to decimal:	0.1	0.01	1.0	10.0	A
3817	14	Which decimal is smallest?	0.9	0.09	0.19	0.29	B
3818	14	3.5 + 1.5 =	4.0	5.0	6.0	7.0	B
3799	13	Riya has 15 apples and gives away 6. Left?	7	8	9	10	C
3800	13	A car travels 60 km in 1 hour. In 3 hours?	120	150	180	200	C
3801	13	5 boxes with 6 pens each. Total pens?	25	30	35	40	B
3802	13	If one notebook costs Rs 45, 3 notebooks cost?	120	125	130	135	D
3803	13	24 meters rope cut into 4 equal parts. Each part?	4	5	6	7	C
3804	13	48 students in 4 equal groups. One group has?	10	11	12	13	C
3805	13	8 bags with 9 marbles each. Total?	63	72	81	90	B
3806	13	A tank has 100 L and 35 L used. Left?	55	60	65	70	C
3807	13	A shop sells 12 pencils per pack. 5 packs = ?	50	55	60	65	C
3808	13	A train leaves at 2 PM and reaches at 6 PM. Travel time?	2h	3h	4h	5h	C
3859	19	If x + 5 = 12, x = ?	5	6	7	8	C
3860	19	If 2x = 14, x = ?	6	7	8	9	B
3861	19	3:6 simplifies to:	1:2	2:1	3:2	6:3	A
3862	19	If y - 4 = 9, y = ?	12	13	14	15	B
3863	19	4:8 equals:	1:2	2:1	4:1	8:1	A
3864	19	x/5 = 3, x = ?	10	12	15	20	C
3865	19	If a = 4, then a + 3 =	5	6	7	8	C
3866	19	If b = 6, then 2b =	10	11	12	13	C
3867	19	Ratio of 10 to 5 is:	1:2	2:1	5:1	10:1	B
3868	19	If p + 8 = 20, p = ?	10	11	12	13	C
3869	20	If x + 5 = 12, x = ?	5	6	7	8	C
3870	20	If 2x = 14, x = ?	6	7	8	9	B
3871	20	3:6 simplifies to:	1:2	2:1	3:2	6:3	A
3872	20	If y - 4 = 9, y = ?	12	13	14	15	B
3873	20	4:8 equals:	1:2	2:1	4:1	8:1	A
3874	20	x/5 = 3, x = ?	10	12	15	20	C
3875	20	If a = 4, then a + 3 =	5	6	7	8	C
3876	20	If b = 6, then 2b =	10	11	12	13	C
3877	20	Ratio of 10 to 5 is:	1:2	2:1	5:1	10:1	B
3878	20	If p + 8 = 20, p = ?	10	11	12	13	C
3919	25	Riya has 15 apples and gives away 6. Left?	7	8	9	10	C
3920	25	A car travels 60 km in 1 hour. In 3 hours?	120	150	180	200	C
3921	25	5 boxes with 6 pens each. Total pens?	25	30	35	40	B
3922	25	If one notebook costs Rs 45, 3 notebooks cost?	120	125	130	135	D
3923	25	24 meters rope cut into 4 equal parts. Each part?	4	5	6	7	C
3924	25	48 students in 4 equal groups. One group has?	10	11	12	13	C
3925	25	8 bags with 9 marbles each. Total?	63	72	81	90	B
3926	25	A tank has 100 L and 35 L used. Left?	55	60	65	70	C
3927	25	A shop sells 12 pencils per pack. 5 packs = ?	50	55	60	65	C
3928	25	A train leaves at 2 PM and reaches at 6 PM. Travel time?	2h	3h	4h	5h	C
4209	54	Which organ pumps blood?	Lungs	Heart	Brain	Kidney	B
4210	54	Which part helps us breathe?	Lungs	Stomach	Liver	Skin	A
4211	54	Which nutrient helps body grow?	Protein	Dust	Stone	Plastic	A
4212	54	Healthy drink for children:	Soda	Energy drink	Water	Ink	C
4213	54	Before eating food, we should:	Play	Wash hands	Sleep	Run	B
4214	54	Which food gives calcium?	Milk	Candy	Chips	Soft drink	A
4215	54	Fruit and vegetables provide:	Vitamins	Smoke	Plastic	Dust	A
4216	54	Main sense organ for taste:	Nose	Tongue	Eyes	Ears	B
4217	54	Teeth help us:	Hear	Chew food	See	Smell	B
4218	54	Balanced diet means:	Only sweets	Only rice	Different healthy food groups	No water	C
4259	59	Which organ pumps blood?	Lungs	Heart	Brain	Kidney	B
3837	16	Units of area are:	cm	cm2	kg	m	B
4260	59	Which part helps us breathe?	Lungs	Stomach	Liver	Skin	A
4261	59	Which nutrient helps body grow?	Protein	Dust	Stone	Plastic	A
4262	59	Healthy drink for children:	Soda	Energy drink	Water	Ink	C
4263	59	Before eating food, we should:	Play	Wash hands	Sleep	Run	B
4264	59	Which food gives calcium?	Milk	Candy	Chips	Soft drink	A
4265	59	Fruit and vegetables provide:	Vitamins	Smoke	Plastic	Dust	A
4266	59	Main sense organ for taste:	Nose	Tongue	Eyes	Ears	B
4267	59	Teeth help us:	Hear	Chew food	See	Smell	B
4268	59	Balanced diet means:	Only sweets	Only rice	Different healthy food groups	No water	C
4309	64	Largest planet in solar system:	Earth	Mars	Jupiter	Venus	C
4310	64	Planet known as Red Planet:	Mercury	Mars	Saturn	Neptune	B
4311	64	Earth takes around __ days around Sun.	200	300	365	500	C
4312	64	Our natural satellite is:	Sun	Moon	Mars	Venus	B
4313	64	Smallest continent:	Europe	Australia	Antarctica	South America	B
4314	64	Largest ocean:	Indian	Atlantic	Pacific	Arctic	C
4315	64	A globe represents:	Only India	Earth	Moon	Weather	B
4316	64	Direction where sun rises:	West	East	North	South	B
4317	64	How many continents are there?	5	6	7	8	C
4318	64	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4079	41	Direct speech uses:	Reported words only	Exact speaker words	Only summaries	Only commands	B
4080	41	Direct speech punctuation uses:	Brackets	Inverted commas	Semicolons	Hyphens only	B
4081	41	He said, 'I am happy.' in indirect becomes:	He said he was happy.	He said I am happy.	He says he is happy.	He told happy.	A
4082	41	In indirect speech, 'am' often changes to:	is	are	was	were	C
4083	41	In indirect speech, 'today' changes to:	today	that day	tomorrow	yesterday always	B
4084	41	In indirect speech, 'will' changes to:	shall	would	can	must	B
4085	41	In indirect speech, 'here' changes to:	here	there	this	that	B
4086	41	Reporting verbs are words like:	said, asked, told	cat, dog, bird	run, jump, play	red, blue, green	A
4087	41	Question in indirect speech generally uses:	if/whether	and	because	so	A
4088	41	Indirect speech usually:	keeps exact words	reports meaning	uses only present tense	removes subject	B
4599	93	UNO stands for:	United Nations Organisation	Universal Nations Office	United National Order	Union of Nations	A
4600	93	Headquarters of UN is in:	London	Paris	New York	Geneva	C
4601	93	G20 is:	20 schools	Group of 20 major economies	20 sports teams	20 cities	B
4602	93	WHO works for:	Road transport	Global health	Space travel	Banking	B
4603	93	Largest democracy is:	India	USA	UK	Japan	A
4604	93	Paris Agreement is about:	Sports	Climate action	Space mission	Trade only	B
4605	93	BRICS includes India with:	Brazil, Russia, China, South Africa	UK, France, Germany, Italy	USA, Japan, Korea, China	None	A
4606	93	UN has approximately how many member countries?	120	150	193	210	C
4607	93	SDGs are related to:	Only sports	Global development goals	Only trade	Movies	B
4608	93	Current affairs means:	Old history only	Recent important happenings	Only science	Only geography	B
3829	16	Area of square side 5 cm:	20 sq cm	25 sq cm	30 sq cm	15 sq cm	B
3830	16	Perimeter of rectangle 6 cm x 4 cm:	20 cm	22 cm	24 cm	18 cm	A
3831	16	Area of rectangle formula:	L+B	2(L+B)	LxB	L-B	C
3832	16	Perimeter of square formula:	2 x side	3 x side	4 x side	side x side	C
3833	16	Area of rectangle 7 cm x 3 cm:	18	20	21	24	C
3834	16	Perimeter of square side 9 cm:	27	36	45	18	B
3835	16	If area=36 and length=9, width is:	3	4	5	6	B
3836	16	A field is 12 m x 8 m. Area:	80	88	96	100	C
3838	16	Units of perimeter are:	cm	cm2	L	kg	A
4219	55	Which is a herbivore?	Lion	Cow	Tiger	Eagle	B
4220	55	Which animal gives us milk?	Dog	Cow	Cat	Goatfish	B
4221	55	Which animal can fly?	Fish	Bird	Elephant	Tiger	B
4222	55	Which animal lives in water?	Lion	Fish	Rabbit	Cow	B
4223	55	A baby dog is called:	Calf	Pup	Foal	Cub	B
4224	55	Which is a wild animal?	Cat	Dog	Tiger	Cow	C
4225	55	Which body covering does a fish have?	Fur	Scales	Feathers	Hair	B
4226	55	Which animal has trunk?	Horse	Elephant	Lion	Cat	B
4227	55	Where do birds lay eggs?	Water	Nest	Cave only	Grass only	B
4228	55	Animals need ___ to survive.	Only toys	Food, water, shelter	Only water	Only air	B
4402	73	Festival of lights:	Holi	Diwali	Eid	Christmas	B
3679	1	What is 3 + 7?	9	12	10	11	C
3680	1	What is 9 + 3?	11	13	14	12	D
3681	1	What is 4 + 9?	12	14	15	13	D
3682	1	What is 9 + 7?	15	18	17	16	D
3683	1	What is 1 + 2?	4	2	3	5	C
3684	1	What is 5 + 10?	16	17	15	14	C
3685	1	What is 10 + 8?	19	20	17	18	D
3686	1	What is 1 + 3?	3	6	4	5	C
3687	1	What is 10 + 7?	16	18	17	19	C
3688	1	What is 5 + 4?	11	10	9	8	C
3689	2	What is 6 - 2?	3	6	4	5	C
3690	2	What is 19 - 18?	1	3	2	0	A
3691	2	What is 12 - 4?	8	9	10	7	A
3692	2	What is 16 - 12?	3	4	6	5	B
3693	2	What is 16 - 14?	2	3	4	1	A
3694	2	What is 14 - 10?	5	6	3	4	D
3695	2	What is 15 - 10?	4	5	7	6	B
3696	2	What is 12 - 1?	11	13	12	10	A
3697	2	What is 8 - 2?	8	5	7	6	D
3698	2	What is 14 - 3?	10	12	11	13	C
3729	6	Which fraction represents 3 parts out of 6 equal parts?	4/6	3/7	3/6	2/6	C
3730	6	Which fraction represents 2 parts out of 3 equal parts?	2/4	3/3	2/3	1/3	C
3731	6	Which fraction represents 1 parts out of 2 equal parts?	1/2	1/3	2/2	1/2	A
3732	6	Which fraction represents 3 parts out of 4 equal parts?	4/4	3/4	3/5	2/4	B
3733	6	Which fraction represents 3 parts out of 6 equal parts?	3/7	4/6	2/6	3/6	D
3734	6	Which fraction represents 4 parts out of 10 equal parts?	3/10	4/11	5/10	4/10	D
3735	6	Which fraction represents 2 parts out of 5 equal parts?	2/6	1/5	2/5	3/5	C
3736	6	Which fraction represents 1 parts out of 6 equal parts?	1/7	1/6	1/6	2/6	B
3737	6	Which fraction represents 1 parts out of 10 equal parts?	1/11	1/10	1/10	2/10	B
3738	6	Which fraction represents 7 parts out of 8 equal parts?	7/8	6/8	7/9	8/8	A
3706	3	Area of rectangle formula:	L+B	LxB	2L+2B only	L-B	B
3759	9	What is 12 x 10?	120	130	132	110	A
3760	9	What is 9 x 8?	80	72	81	64	B
3761	9	What is 6 x 6?	36	30	42	42	A
3762	9	What is 3 x 12?	24	36	39	48	B
3763	9	What is 12 x 8?	96	88	104	108	A
3764	9	What is 7 x 12?	96	72	91	84	D
3765	9	What is 9 x 6?	63	48	54	60	C
3766	9	What is 6 x 10?	60	66	70	50	A
3767	9	What is 8 x 3?	27	32	21	24	D
3768	9	What is 5 x 2?	10	12	15	8	A
3769	10	What is 27 / 3?	9	10	8	11	A
3770	10	What is 15 / 5?	4	5	2	3	D
3771	10	What is 48 / 8?	8	5	7	6	D
3772	10	What is 10 / 5?	3	2	4	1	B
3773	10	What is 24 / 12?	3	4	2	1	C
3774	10	What is 60 / 10?	8	7	5	6	D
3775	10	What is 54 / 6?	10	11	9	8	C
3776	10	What is 80 / 10?	9	8	10	7	B
3777	10	What is 55 / 5?	10	12	13	11	D
3778	10	What is 15 / 5?	3	5	4	2	A
3753	8	How many hours in 1 day?	12	18	24	48	C
3849	18	Which fraction represents 5 parts out of 6 equal parts?	6/6	5/7	5/6	4/6	C
3850	18	Which fraction represents 7 parts out of 10 equal parts?	8/10	7/10	7/11	6/10	B
3851	18	Which fraction represents 3 parts out of 5 equal parts?	4/5	3/6	2/5	3/5	D
3852	18	Which fraction represents 6 parts out of 8 equal parts?	5/8	6/9	6/8	7/8	C
3853	18	Which fraction represents 1 parts out of 8 equal parts?	1/8	1/9	2/8	1/8	A
3854	18	Which fraction represents 6 parts out of 10 equal parts?	5/10	6/11	7/10	6/10	D
3855	18	Which fraction represents 1 parts out of 2 equal parts?	1/2	1/3	2/2	1/2	A
3856	18	Which fraction represents 3 parts out of 4 equal parts?	3/4	2/4	4/4	3/5	A
3857	18	Which fraction represents 3 parts out of 5 equal parts?	3/5	4/5	2/5	3/6	A
3858	18	Which fraction represents 2 parts out of 3 equal parts?	3/3	2/4	1/3	2/3	D
3889	22	A vehicle moves at 60 km/h for 3 hours. Distance?	190	180	120	240	B
3890	22	A vehicle moves at 20 km/h for 2 hours. Distance?	40	20	60	50	A
3891	22	A vehicle moves at 60 km/h for 3 hours. Distance?	180	190	120	240	A
3892	22	A vehicle moves at 20 km/h for 2 hours. Distance?	20	60	40	50	C
3893	22	A vehicle moves at 50 km/h for 2 hours. Distance?	110	100	150	50	B
3894	22	A vehicle moves at 50 km/h for 5 hours. Distance?	250	260	200	300	A
3895	22	A vehicle moves at 40 km/h for 2 hours. Distance?	90	80	120	40	B
3896	22	A vehicle moves at 60 km/h for 3 hours. Distance?	120	190	180	240	C
3897	22	A vehicle moves at 40 km/h for 4 hours. Distance?	170	200	120	160	D
3898	22	A vehicle moves at 20 km/h for 5 hours. Distance?	120	100	80	110	B
3909	24	What is 50% of 200?	110	105	95	100	D
3910	24	What is 25% of 200?	60	45	50	55	C
3911	24	What is 50% of 100?	50	60	55	45	A
3912	24	What is 10% of 120?	7	22	12	17	C
3913	24	What is 75% of 120?	90	85	100	95	A
3914	24	What is 75% of 120?	85	95	90	100	C
3915	24	What is 20% of 40?	13	3	8	18	C
3916	24	What is 20% of 120?	24	19	29	34	A
3917	24	What is 50% of 40?	30	20	25	15	B
3918	24	What is 10% of 100?	10	20	15	5	A
3929	26	Which spelling is correct? (1)	freinde	friend	freind	frien	B
3930	26	Which spelling is correct? (2)	school	schol	schole	schoo	A
3931	26	Which spelling is correct? (3)	becousee	because	becaus	becouse	B
3932	26	Which spelling is correct? (4)	beautiful	beautifull	beautifu	beautifulle	A
3933	26	Which spelling is correct? (5)	mornninge	mornning	mornin	morning	D
3934	26	Which spelling is correct? (6)	teacher	techer	techere	teache	A
3935	26	Which spelling is correct? (7)	country	contry	countr	contrye	A
3936	26	Which spelling is correct? (8)	sciense	scienc	sciensee	science	D
3937	26	Which spelling is correct? (9)	language	langauge	langaugee	languag	A
3938	26	Which spelling is correct? (10)	calenda	calender	calendar	calendere	C
3905	23	Mean of 4,6,8 is:	5	6	7	8	B
3979	31	Which punctuation ends a question? (1)	.	,	?	!	C
3980	31	Which punctuation ends a question? (2)	.	,	?	!	C
3981	31	Which punctuation ends a question? (3)	.	,	?	!	C
3982	31	Which punctuation ends a question? (4)	.	,	?	!	C
3983	31	Which punctuation ends a question? (5)	.	,	?	!	C
3984	31	Which punctuation ends a question? (6)	.	,	?	!	C
3985	31	Which punctuation ends a question? (7)	.	,	?	!	C
3986	31	Which punctuation ends a question? (8)	.	,	?	!	C
3987	31	Which punctuation ends a question? (9)	.	,	?	!	C
3988	31	Which punctuation ends a question? (10)	.	,	?	!	C
3952	28	Which is a vowel?	B	D	E	T	C
4039	37	What is a synonym of 'happy'?	happyly	happy	word with similar meaning	opposite meaning	C
4040	37	What is a synonym of 'bright'?	brightly	bright	word with similar meaning	opposite meaning	C
4041	37	What is a synonym of 'quick'?	quickly	quick	word with similar meaning	opposite meaning	C
4042	37	What is a synonym of 'strong'?	strongly	strong	word with similar meaning	opposite meaning	C
4043	37	What is a synonym of 'gentle'?	gentlely	gentle	word with similar meaning	opposite meaning	C
4044	37	What is a synonym of 'ancient'?	anciently	ancient	word with similar meaning	opposite meaning	C
4045	37	What is a synonym of 'tiny'?	tinyly	tiny	word with similar meaning	opposite meaning	C
4046	37	What is a synonym of 'brave'?	bravely	brave	word with similar meaning	opposite meaning	C
4047	37	What is a synonym of 'smart'?	smartly	smart	word with similar meaning	opposite meaning	C
4048	37	What is a synonym of 'silent'?	silently	silent	word with similar meaning	opposite meaning	C
4109	44	What is a synonym of 'happy'?	happyly	happy	word with similar meaning	opposite meaning	C
4110	44	What is a synonym of 'bright'?	brightly	bright	word with similar meaning	opposite meaning	C
4111	44	What is a synonym of 'quick'?	quickly	quick	word with similar meaning	opposite meaning	C
4112	44	What is a synonym of 'strong'?	strongly	strong	word with similar meaning	opposite meaning	C
4113	44	What is a synonym of 'gentle'?	gentlely	gentle	word with similar meaning	opposite meaning	C
4114	44	What is a synonym of 'ancient'?	anciently	ancient	word with similar meaning	opposite meaning	C
4115	44	What is a synonym of 'tiny'?	tinyly	tiny	word with similar meaning	opposite meaning	C
4116	44	What is a synonym of 'brave'?	bravely	brave	word with similar meaning	opposite meaning	C
4117	44	What is a synonym of 'smart'?	smartly	smart	word with similar meaning	opposite meaning	C
4118	44	What is a synonym of 'silent'?	silently	silent	word with similar meaning	opposite meaning	C
4179	51	Which organ pumps blood?	Lungs	Heart	Brain	Stomach	B
4180	51	Which part helps us breathe?	Liver	Lungs	Kidneys	Skin	B
4181	51	How many eyes does a person have?	1	2	3	4	B
4182	51	Which part helps us smell?	Ears	Nose	Tongue	Eyes	B
4183	51	Which part helps us hear?	Eyes	Nose	Ears	Hands	C
4184	51	What protects our brain?	Skull	Ribs	Teeth	Nails	A
4185	51	How many legs do humans have?	1	2	3	4	B
4186	51	Which body part tastes food?	Tongue	Nose	Ear	Hand	A
4187	51	Bones give our body?	Color	Shape and support	Food	Water	B
3949	28	How many letters are there in the English alphabet?	24	25	26	27	C
3950	28	Which letter comes after M?	L	N	O	P	B
3951	28	Which letter comes before G?	E	F	H	I	B
3953	28	Which letter starts the word 'Ball'?	A	B	C	D	B
3954	28	What is the last letter of the alphabet?	X	Y	Z	W	C
3955	28	How many vowels are there?	4	5	6	7	B
3956	28	Which is NOT a vowel?	A	E	I	R	D
3957	28	Which letter comes after Q?	P	R	S	T	B
3958	28	Which letter comes before A?	Z	B	C	No letter	D
3959	29	Which word is a noun?	Run	Blue	Dog	Quickly	C
3960	29	Which is a naming word?	Jump	Book	Slowly	Very	B
3961	29	Which is a place?	School	Happy	Write	Fast	A
3962	29	Which is a person?	Teacher	Tall	Go	Blue	A
3963	29	Which is an animal?	Table	Cat	Sing	Kind	B
3964	29	Choose the noun.	Quick	Pen	Run	Under	B
3965	29	Which word names a thing?	Apple	Eat	Soft	Soon	A
4188	51	Which sense organ sees?	Eyes	Ears	Nose	Skin	A
4199	53	What causes rain?	Clouds releasing water	Trees	Mountains	Roads	A
4200	53	Hottest season in India?	Winter	Monsoon	Summer	Autumn	C
4201	53	Tool used to measure temperature?	Ruler	Thermometer	Scale	Compass	B
4202	53	Frozen water is called?	Steam	Ice	Cloud	Fog	B
4203	53	Wind is moving?	Water	Air	Light	Heat	B
4204	53	Rainy season in India?	Summer	Monsoon	Winter	Spring	B
4205	53	Clouds are made of tiny?	Rocks	Dust only	Water droplets	Leaves	C
4206	53	A rainbow is seen when sunlight and?	Dust	Rain droplets	Snow only	Fog only	B
4207	53	Climate means weather over?	A day	Many years	An hour	A week only	B
4208	53	Main greenhouse gas?	Oxygen	Carbon dioxide	Helium	Argon	B
3966	29	Which is NOT a noun?	Ball	River	Play	Girl	C
3939	27	Which word rhymes with CAT?	dog	bat	cup	sun	B
3940	27	Which word rhymes with SUN?	fun	tree	book	ball	A
3941	27	Which word rhymes with CAKE?	lake	rice	soap	leaf	A
3942	27	Which word rhymes with TREE?	bee	cup	mat	pen	A
3967	29	Which sentence has a noun?	Run fast	The bird flies	Very quickly	Come here	B
3968	29	Noun means:	Action word	Naming word	Joining word	Describing word	B
4019	35	An adjective describes a:	Noun	Verb	Preposition	Punctuation	A
4020	35	Choose the adjective: 'red apple'	red	apple	is	the	A
4021	35	Which is an adjective?	Quick	Run	Table	Under	A
4022	35	In 'big house', adjective is:	big	house	is	none	A
4023	35	Adjective tells us about:	Action	Naming word	Quality	Question	C
4024	35	Pick the adjective.	Tall	Jump	Book	Happily	A
4025	35	Which is NOT an adjective?	Blue	Happy	Read	Small	C
4026	35	In 'sweet mango', adjective is:	sweet	mango	is	none	A
4027	35	Adjectives answer which kind of question?	How many/what kind	Where	When	Why only	A
4028	35	Which phrase has an adjective?	run quickly	bright sun	eat rice	go home	B
4009	34	Which word is a verb?	Chair	Run	Blue	Tall	B
4010	34	Which sentence has a verb?	The happy boy	Birds fly	Blue sky	Tall tree	B
4011	34	A verb shows:	Action	Color	Number	Place	A
4012	34	Choose the verb.	Quickly	Dance	Table	Heavy	B
4013	34	Which is an action word?	Jump	Apple	Kind	Slow	A
4014	34	Which is NOT a verb?	Write	Sing	Book	Read	C
4015	34	He ___ to school.	run	runs	running	raning	B
4016	34	They ___ football.	plays	play	playing	is play	B
4017	34	Which word tells what someone does?	Eat	Red	Soft	Near	A
4018	34	Verb in 'The cat sleeps' is:	cat	the	sleeps	none	C
3943	27	Which word rhymes with PLAY?	day	read	jump	run	A
3944	27	Which word rhymes with BOOK?	cook	table	shoe	car	A
4069	40	Mean is also called:	Mode	Median	Average	Range	C
4070	40	Median is:	Most frequent	Middle value	Difference max-min	Total	B
4071	40	Mode is:	Middle value	Most frequent value	Average	Difference	B
4072	40	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
4073	40	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
4074	40	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
4075	40	Mean of 4,6,8 is:	5	6	7	8	B
4076	40	Median of 1,3,5,7,9 is:	3	5	7	9	B
4077	40	Mode of 2,3,3,4 is:	2	3	4	No mode	B
4078	40	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
4049	38	Which is a preposition?	Under	Run	Happy	Book	A
4050	38	The cat is ___ the table.	in	run	blue	jump	A
4051	38	Prepositions show:	Action	Position/relationship	Color	Feeling	B
4052	38	Choose preposition of place.	Behind	Sing	Soft	Apple	A
4053	38	We sat ___ the tree.	under	eat	quick	book	A
4054	38	She arrived ___ 9 AM.	at	run	blue	tall	A
4055	38	Bird flew ___ the river.	over	read	small	table	A
4056	38	I kept the pen ___ the box.	in	fast	walk	nice	A
4057	38	Which is NOT a preposition?	on	under	slowly	behind	C
4058	38	The ball rolled ___ the chair.	under	happy	write	big	A
4449	78	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4450	78	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4451	78	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4452	78	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4453	78	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4454	78	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4455	78	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4456	78	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4457	78	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4458	78	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4489	82	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4490	82	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4491	82	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4492	82	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4493	82	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4494	82	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4495	82	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4496	82	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4497	82	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4498	82	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4519	85	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4520	85	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4521	85	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4522	85	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4523	85	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4524	85	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4525	85	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4526	85	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4527	85	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4528	85	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4499	83	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4500	83	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4501	83	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4502	83	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4503	83	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4504	83	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4505	83	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4506	83	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4507	83	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4508	83	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4539	87	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4540	87	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4541	87	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4542	87	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4543	87	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4544	87	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4545	87	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4546	87	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4547	87	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4548	87	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4529	86	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4530	86	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4531	86	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4532	86	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4533	86	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4534	86	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4535	86	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4536	86	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4537	86	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4538	86	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4579	91	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4580	91	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4581	91	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4582	91	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4583	91	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4584	91	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4585	91	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4586	91	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4587	91	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4588	91	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4589	92	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4590	92	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4591	92	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4592	92	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4593	92	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4594	92	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4595	92	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4596	92	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4597	92	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4598	92	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4609	94	Mean is also called:	Mode	Median	Average	Range	C
4610	94	Median is:	Most frequent	Middle value	Difference max-min	Total	B
4611	94	Mode is:	Middle value	Most frequent value	Average	Difference	B
4612	94	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
4613	94	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
4614	94	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
4615	94	Mean of 4,6,8 is:	5	6	7	8	B
4616	94	Median of 1,3,5,7,9 is:	3	5	7	9	B
4617	94	Mode of 2,3,3,4 is:	2	3	4	No mode	B
4618	94	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
4639	97	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4640	97	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4559	89	Largest planet in solar system:	Earth	Mars	Jupiter	Venus	C
4641	97	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4642	97	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4643	97	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4644	97	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4645	97	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4646	97	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4647	97	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4648	97	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4629	96	Mean is also called:	Mode	Median	Average	Range	C
4630	96	Median is:	Most frequent	Middle value	Difference max-min	Total	B
4631	96	Mode is:	Middle value	Most frequent value	Average	Difference	B
4632	96	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
4633	96	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
4634	96	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
4635	96	Mean of 4,6,8 is:	5	6	7	8	B
4636	96	Median of 1,3,5,7,9 is:	3	5	7	9	B
4637	96	Mode of 2,3,3,4 is:	2	3	4	No mode	B
4638	96	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
4649	98	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4650	98	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4651	98	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4652	98	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4653	98	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4654	98	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4655	98	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4656	98	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4657	98	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4658	98	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4659	99	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4660	99	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4661	99	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
3719	5	What comes after 19?	18	20	21	22	B
3720	5	What comes before 40?	39	41	38	42	A
3721	5	2, 4, 6, __	7	8	9	10	B
3722	5	5, 10, 15, __	18	20	25	30	B
3723	5	1, 3, 5, __	6	7	8	9	B
3724	5	10, 9, 8, __	7	6	5	4	A
3725	5	A, B, A, B, __	C	A	B	D	B
3726	5	Red, Blue, Red, Blue, __	Green	Blue	Red	Yellow	C
3727	5	How many months are there in a year?	10	11	12	13	C
3728	5	How many days are there in a week?	5	6	7	8	C
3709	4	What comes after 19?	18	20	21	22	B
3710	4	What comes before 40?	39	41	38	42	A
3711	4	2, 4, 6, __	7	8	9	10	B
3712	4	5, 10, 15, __	18	20	25	30	B
3713	4	1, 3, 5, __	6	7	8	9	B
3714	4	10, 9, 8, __	7	6	5	4	A
3715	4	A, B, A, B, __	C	A	B	D	B
3716	4	Red, Blue, Red, Blue, __	Green	Blue	Red	Yellow	C
3717	4	How many months are there in a year?	10	11	12	13	C
3718	4	How many days are there in a week?	5	6	7	8	C
3699	3	How many sides does a triangle have?	2	3	4	5	B
3700	3	How many sides does a square have?	3	4	5	6	B
3701	3	A circle has how many corners?	0	1	2	4	A
3702	3	A shape with 5 sides is called:	Hexagon	Pentagon	Triangle	Rectangle	B
3703	3	How many sides does a hexagon have?	5	6	7	8	B
3704	3	A right angle measures:	45°	60°	90°	120°	C
3705	3	Perimeter means:	Inside space	Boundary length	Weight	Volume	B
3707	3	A cube has how many faces?	4	5	6	8	C
3708	3	A rectangle has opposite sides:	Unequal	Equal	Curved	No sides	B
3749	8	100 centimeters = ?	1 meter	10 meters	100 meters	50 cm	A
3750	8	1 kilogram = ?	100 g	500 g	1000 g	2000 g	C
3751	8	Unit for liquid amount:	Meter	Litre	Kilogram	Second	B
3752	8	How many minutes in 1 hour?	30	45	60	90	C
3754	8	How many days in a week?	5	6	7	8	C
3755	8	How many months in a year?	10	11	12	13	C
3756	8	Leap year has days:	365	366	364	360	B
3757	8	February usually has:	28	29	30	31	A
3758	8	Tool to measure length:	Clock	Ruler	Scale for weight	Thermometer	B
3739	7	In 34, digit in tens place is:	4	3	0	7	B
3740	7	In 52, digit in ones place is:	5	2	7	0	B
3741	7	Place value of 6 in 67:	6	60	600	16	B
3742	7	4 tens and 2 ones make:	24	42	44	22	B
3743	7	Value of 5 in 56 is:	5	50	500	15	B
3744	7	7 tens and 0 ones equals:	7	17	70	77	C
3745	7	In 89, ones digit is:	8	9	0	7	B
3746	7	In 123, hundreds digit is:	1	2	3	0	A
3747	7	Number with 3 hundreds, 2 tens, 1 one:	312	321	231	123	B
3748	7	In 405, tens digit is:	4	0	5	none	B
3819	15	Mean is also called:	Mode	Median	Average	Range	C
3820	15	Median is:	Most frequent	Middle value	Difference max-min	Total	B
3821	15	Mode is:	Middle value	Most frequent value	Average	Difference	B
3822	15	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
3823	15	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
3824	15	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
3825	15	Mean of 4,6,8 is:	5	6	7	8	B
3826	15	Median of 1,3,5,7,9 is:	3	5	7	9	B
3827	15	Mode of 2,3,3,4 is:	2	3	4	No mode	B
3828	15	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
3809	14	0.5 is equal to:	1/4	1/2	3/4	2/3	B
3779	11	How many sides does a triangle have?	2	3	4	5	B
3780	11	How many sides does a square have?	3	4	5	6	B
3781	11	A circle has how many corners?	0	1	2	4	A
3782	11	A shape with 5 sides is called:	Hexagon	Pentagon	Triangle	Rectangle	B
3783	11	How many sides does a hexagon have?	5	6	7	8	B
3784	11	A right angle measures:	45°	60°	90°	120°	C
3785	11	Perimeter means:	Inside space	Boundary length	Weight	Volume	B
3786	11	Area of rectangle formula:	L+B	LxB	2L+2B only	L-B	B
3787	11	A cube has how many faces?	4	5	6	8	C
3788	11	A rectangle has opposite sides:	Unequal	Equal	Curved	No sides	B
3789	12	100 centimeters = ?	1 meter	10 meters	100 meters	50 cm	A
3790	12	1 kilogram = ?	100 g	500 g	1000 g	2000 g	C
3791	12	Unit for liquid amount:	Meter	Litre	Kilogram	Second	B
3792	12	How many minutes in 1 hour?	30	45	60	90	C
3793	12	How many hours in 1 day?	12	18	24	48	C
3794	12	How many days in a week?	5	6	7	8	C
3795	12	How many months in a year?	10	11	12	13	C
3796	12	Leap year has days:	365	366	364	360	B
3797	12	February usually has:	28	29	30	31	A
3798	12	Tool to measure length:	Clock	Ruler	Scale for weight	Thermometer	B
4412	74	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
3839	17	Mean is also called:	Mode	Median	Average	Range	C
3840	17	Median is:	Most frequent	Middle value	Difference max-min	Total	B
3841	17	Mode is:	Middle value	Most frequent value	Average	Difference	B
3842	17	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
3843	17	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
3844	17	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
3845	17	Mean of 4,6,8 is:	5	6	7	8	B
3846	17	Median of 1,3,5,7,9 is:	3	5	7	9	B
3847	17	Mode of 2,3,3,4 is:	2	3	4	No mode	B
3848	17	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
3811	14	0.25 is equal to:	1/2	1/3	1/4	3/4	C
3879	21	CP=100, SP=120. Profit is:	10	15	20	25	C
3880	21	CP=200, SP=180. Loss is:	10	15	20	30	C
3881	21	Profit % formula:	Profit/SP x100	Profit/CP x100	CP/Profit x100	SP/CP x100	B
3882	21	Loss % formula:	Loss/CP x100	Loss/SP x100	CP/Loss x100	SP/Loss x100	A
3883	21	CP=500, profit=50. Profit %?	5%	10%	15%	20%	B
3884	21	If SP>CP then there is:	Loss	Profit	No gain/loss	None	B
3885	21	If SP<CP then there is:	Profit	Loss	No gain/loss	None	B
3886	21	CP=250, SP=300. Profit?	40	45	50	55	C
3887	21	SP=450, CP=500. Loss?	40	45	50	55	C
3888	21	CP=400, profit 25%. SP?	450	480	500	520	C
3899	23	Mean is also called:	Mode	Median	Average	Range	C
3900	23	Median is:	Most frequent	Middle value	Difference max-min	Total	B
3901	23	Mode is:	Middle value	Most frequent value	Average	Difference	B
3902	23	Range = ?	Max - Min	Max + Min	Total/Count	Middle value	A
3903	23	Bar graph uses:	Bars	Circles	Lines only	Pictures only	A
3904	23	Pie chart is drawn as:	Circle sectors	Rectangles	Lines	Dots	A
3906	23	Median of 1,3,5,7,9 is:	3	5	7	9	B
3907	23	Mode of 2,3,3,4 is:	2	3	4	No mode	B
3908	23	Best graph for trend over time:	Pie chart	Line graph	Bar graph	Table only	B
4189	52	Which organ pumps blood?	Lungs	Heart	Brain	Kidney	B
4190	52	Which part helps us breathe?	Lungs	Stomach	Liver	Skin	A
4191	52	Which nutrient helps body grow?	Protein	Dust	Stone	Plastic	A
4192	52	Healthy drink for children:	Soda	Energy drink	Water	Ink	C
4193	52	Before eating food, we should:	Play	Wash hands	Sleep	Run	B
4194	52	Which food gives calcium?	Milk	Candy	Chips	Soft drink	A
4195	52	Fruit and vegetables provide:	Vitamins	Smoke	Plastic	Dust	A
4196	52	Main sense organ for taste:	Nose	Tongue	Eyes	Ears	B
4197	52	Teeth help us:	Hear	Chew food	See	Smell	B
4198	52	Balanced diet means:	Only sweets	Only rice	Different healthy food groups	No water	C
4249	58	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4250	58	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4251	58	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4252	58	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4253	58	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4254	58	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4255	58	Boiling point of water is:	50C	75C	100C	120C	C
4256	58	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4257	58	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4258	58	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4239	57	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4240	57	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4241	57	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4242	57	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4243	57	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4244	57	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4245	57	Boiling point of water is:	50C	75C	100C	120C	C
4246	57	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4247	57	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4248	57	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4229	56	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4230	56	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4231	56	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4232	56	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4233	56	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4234	56	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4235	56	Boiling point of water is:	50C	75C	100C	120C	C
4236	56	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4237	56	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4238	56	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4269	60	Which organ pumps blood?	Lungs	Heart	Brain	Kidney	B
4270	60	Which part helps us breathe?	Lungs	Stomach	Liver	Skin	A
4271	60	Which nutrient helps body grow?	Protein	Dust	Stone	Plastic	A
4272	60	Healthy drink for children:	Soda	Energy drink	Water	Ink	C
4273	60	Before eating food, we should:	Play	Wash hands	Sleep	Run	B
4274	60	Which food gives calcium?	Milk	Candy	Chips	Soft drink	A
4275	60	Fruit and vegetables provide:	Vitamins	Smoke	Plastic	Dust	A
4276	60	Main sense organ for taste:	Nose	Tongue	Eyes	Ears	B
4277	60	Teeth help us:	Hear	Chew food	See	Smell	B
4278	60	Balanced diet means:	Only sweets	Only rice	Different healthy food groups	No water	C
4279	61	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4280	61	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4281	61	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4282	61	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4283	61	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4284	61	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4285	61	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4286	61	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4287	61	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4288	61	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4289	62	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4290	62	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4291	62	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4292	62	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4293	62	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4294	62	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4295	62	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4296	62	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4297	62	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4298	62	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4299	63	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4300	63	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4301	63	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4302	63	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4303	63	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4304	63	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4305	63	Boiling point of water is:	50C	75C	100C	120C	C
4306	63	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4307	63	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4308	63	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4319	65	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4369	70	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4370	70	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4371	70	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4372	70	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4373	70	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4374	70	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4375	70	Boiling point of water is:	50C	75C	100C	120C	C
4376	70	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4377	70	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4378	70	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4348	67	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4349	68	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4350	68	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4351	68	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4352	68	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4353	68	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4354	68	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4355	68	Boiling point of water is:	50C	75C	100C	120C	C
4356	68	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4357	68	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4358	68	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4409	74	A magnet attracts mostly:	Wood	Iron	Plastic	Glass	B
4410	74	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4411	74	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4413	74	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4414	74	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4415	74	Boiling point of water is:	50C	75C	100C	120C	C
4416	74	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4417	74	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4418	74	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4379	71	Which organ pumps blood?	Lungs	Heart	Brain	Kidney	B
4380	71	Which part helps us breathe?	Lungs	Stomach	Liver	Skin	A
4381	71	Which nutrient helps body grow?	Protein	Dust	Stone	Plastic	A
4382	71	Healthy drink for children:	Soda	Energy drink	Water	Ink	C
4383	71	Before eating food, we should:	Play	Wash hands	Sleep	Run	B
4384	71	Which food gives calcium?	Milk	Candy	Chips	Soft drink	A
4385	71	Fruit and vegetables provide:	Vitamins	Smoke	Plastic	Dust	A
4386	71	Main sense organ for taste:	Nose	Tongue	Eyes	Ears	B
4387	71	Teeth help us:	Hear	Chew food	See	Smell	B
4388	71	Balanced diet means:	Only sweets	Only rice	Different healthy food groups	No water	C
4389	72	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4390	72	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4391	72	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4392	72	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4393	72	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4394	72	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4395	72	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4396	72	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4397	72	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4398	72	Global warming leads to:	No climate change	Rising temperatures	Cooler Earth always	No effect	B
4399	73	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4400	73	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4401	73	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4403	73	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4404	73	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4405	73	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4406	73	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4407	73	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4408	73	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4320	65	Like poles of magnets:	Attract	Repel	Disappear	Melt	B
4321	65	Main source of natural light:	Moon	Sun	Bulb	Torch	B
4322	65	Shadow forms when light is:	Blocked	Doubled	Heated	Frozen	A
4323	65	Gas we breathe in:	Carbon dioxide	Oxygen	Hydrogen	Helium	B
4324	65	Three states of matter:	Hot-cold-warm	Solid-liquid-gas	Big-small-medium	Up-down-side	B
4325	65	Boiling point of water is:	50C	75C	100C	120C	C
4326	65	Simple machine example:	Seesaw	Laptop	Phone	TV	A
4327	65	Electric circuit needs:	Closed path	Open path	No wire	Only battery	A
4328	65	Energy from sun is:	Solar energy	Wind energy	Hydro energy	Nuclear only	A
4329	66	Adaptation means:	Random change	Features helping survival	Daily habits	Weather report	B
4330	66	Camel hump helps by:	Storing fat	Flying	Swimming	Climbing	A
4331	66	Polar bear has thick fur for:	Fashion	Keeping warm	Hunting only	Swimming faster	B
4332	66	Fish have gills to:	Walk on land	Breathe in water	See clearly	Store food	B
4333	66	Cactus thick stem helps:	Store water	Catch birds	Grow faster always	Change color	A
4334	66	Duck has webbed feet for:	Flying	Swimming	Climbing	Digging	B
4335	66	Camouflage helps animals:	Run faster	Hide from enemies	Eat more	Grow bigger	B
4336	66	Hibernation is:	Summer sleep	Winter sleep	Daily sleep	No sleep	B
4337	66	Migration means:	Staying in one place	Moving to another place seasonally	Sleeping longer	Color change	B
4338	66	Adaptations are usually linked to:	Habitat	Only food	Only weather	Only age	A
4339	67	Ecosystem means:	Only animals	Living things + environment	Only plants	Only air	B
4340	67	Food chain starts with:	Carnivore	Producer/plant	Herbivore	Decomposer	B
4341	67	Deforestation means:	Planting trees	Cutting forests	Cleaning rivers	Saving animals	B
4342	67	Main greenhouse gas:	Oxygen	Carbon dioxide	Helium	Nitrogen	B
4343	67	Reduce-Reuse-Recycle are called:	3 Rs	3 Ps	3 Cs	3 As	A
4344	67	Air pollution mostly caused by:	Trees	Vehicle/factory smoke	Rain	Sunlight	B
4345	67	Renewable energy example:	Coal	Solar	Petrol	Diesel	B
4346	67	Saving water is called:	Water pollution	Water conservation	Water waste	Water loss	B
4347	67	Soil pollution can be caused by:	Excess chemicals	Rain	Clouds	Wind only	A
4429	76	What sound does a dog make?	Meow	Moo	Bark	Neigh	C
4419	75	What causes rain?	Clouds releasing water	Trees	Mountains	Roads	A
4420	75	Hottest season in India?	Winter	Monsoon	Summer	Autumn	C
4421	75	Tool used to measure temperature?	Ruler	Thermometer	Scale	Compass	B
4422	75	Frozen water is called?	Steam	Ice	Cloud	Fog	B
4423	75	Wind is moving?	Water	Air	Light	Heat	B
4424	75	Rainy season in India?	Summer	Monsoon	Winter	Spring	B
4425	75	Clouds are made of tiny?	Rocks	Dust only	Water droplets	Leaves	C
4426	75	A rainbow is seen when sunlight and?	Dust	Rain droplets	Snow only	Fog only	B
4427	75	Climate means weather over?	A day	Many years	An hour	A week only	B
4428	75	Main greenhouse gas?	Oxygen	Carbon dioxide	Helium	Argon	B
4439	77	Capital of India?	Mumbai	New Delhi	Kolkata	Chennai	B
4440	77	National animal of India?	Elephant	Tiger	Lion	Leopard	B
4441	77	National bird of India?	Parrot	Peacock	Sparrow	Crow	B
4442	77	Indian currency?	Dollar	Euro	Rupee	Yen	C
4443	77	Independence Day of India?	26 Jan	15 Aug	2 Oct	14 Nov	B
4444	77	National flower of India?	Rose	Lotus	Jasmine	Lily	B
4445	77	Tricolor has how many colors?	2	3	4	5	B
4446	77	Who wrote national anthem?	Tagore	Gandhi	Nehru	Kalam	A
4447	77	Ashoka Chakra has how many spokes?	12	18	24	30	C
4448	77	Largest democracy?	USA	India	UK	Japan	B
4479	81	Players in a cricket team?	9	10	11	12	C
4480	81	Players in football team?	9	10	11	12	C
4481	81	Game with shuttlecock?	Tennis	Badminton	Hockey	Cricket	B
4482	81	Olympics held every?	2 years	3 years	4 years	5 years	C
4483	81	Bat and ball game?	Cricket	Chess	Kabaddi	Boxing	A
4484	81	Wimbledon is for?	Cricket	Tennis	Football	Golf	B
4485	81	National sport (school GK expectation)?	Hockey	Cricket	Football	Tennis	A
4486	81	Basketball team players?	4	5	6	7	B
4487	81	Highest runs in one legal cricket ball?	4	5	6	7	C
4488	81	Swimming done in?	Court	Track	Pool	Field	C
4549	88	Capital of India?	Mumbai	New Delhi	Kolkata	Chennai	B
4550	88	National animal of India?	Elephant	Tiger	Lion	Leopard	B
4551	88	National bird of India?	Parrot	Peacock	Sparrow	Crow	B
4552	88	Indian currency?	Dollar	Euro	Rupee	Yen	C
4553	88	Independence Day of India?	26 Jan	15 Aug	2 Oct	14 Nov	B
4554	88	National flower of India?	Rose	Lotus	Jasmine	Lily	B
4555	88	Tricolor has how many colors?	2	3	4	5	B
4556	88	Who wrote national anthem?	Tagore	Gandhi	Nehru	Kalam	A
4557	88	Ashoka Chakra has how many spokes?	12	18	24	30	C
4558	88	Largest democracy?	USA	India	UK	Japan	B
4669	100	First human on Moon:	Yuri Gagarin	Neil Armstrong	Buzz Aldrin	Kalpana Chawla	B
4670	100	Our galaxy is called:	Andromeda	Milky Way	Orion	Sombrero	B
4671	100	Capital of India:	Mumbai	New Delhi	Kolkata	Chennai	B
4672	100	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4673	100	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4674	100	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4675	100	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4676	100	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4677	100	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4678	100	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
4662	99	Festival of lights:	Holi	Diwali	Eid	Christmas	B
4663	99	Fastest transport:	Bicycle	Bus	Airplane	Ship	C
4664	99	WWW stands for:	World Wide Web	Wide Web World	Web World Wide	World Web Way	A
4665	99	CPU stands for:	Central Processing Unit	Computer Process Utility	Central Program Unit	Core Processing Unit	A
4666	99	India's highest civilian award:	Padma Shri	Bharat Ratna	Arjuna Award	Param Vir Chakra	B
4667	99	Author of Harry Potter:	J.R.R. Tolkien	J.K. Rowling	Roald Dahl	C.S. Lewis	B
4668	99	Largest ocean:	Atlantic	Indian	Pacific	Arctic	C
\.


--
-- Data for Name: results; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.results (result_id, student_id, student_name, subject_name, topic_name, grade, score, total_questions, attempted_at) FROM stdin;
34	13	Tanishq Mhatre	Mathematics	Fractions Advanced	4	2	10	2026-04-20 11:05:29.892278+00
35	13	Tanishq Mhatre	Mathematics	Data & Graphs	4	3	10	2026-04-20 19:00:19.829028+00
36	13	Tanishq Mhatre	General Knowledge	Awards & Honours	4	8	10	2026-04-20 19:01:21.099344+00
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.students (student_id, username, password_hash, display_name, grade, total_points, current_streak, longest_streak, last_quiz_date, created_at) FROM stdin;
14	piyushgharat63	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	Piyush	5	0	0	0	\N	2026-04-19 17:51:42.709488+00
13	tanishq	fbc9754bfd2b97be7ef5097bd64f7b4dc14211765141c72451acce3cde907f57	Tanishq Mhatre	4	130	1	1	2026-04-20	2026-04-19 17:49:13.993277+00
\.


--
-- Data for Name: subjects; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.subjects (subject_id, subject_name, icon, color_class) FROM stdin;
1	Mathematics	fa-calculator	subject-blue
2	English	fa-book	subject-green
3	Science	fa-flask	subject-yellow
4	General Knowledge	fa-globe	subject-pink
\.


--
-- Data for Name: topics; Type: TABLE DATA; Schema: railway; Owner: mindsprouts_user
--

COPY railway.topics (topic_id, subject_id, topic_name, grade) FROM stdin;
1	1	Addition	1
2	1	Subtraction	1
3	1	Shapes	1
4	1	Counting	1
5	1	Basic Patterns	1
6	1	Fractions	2
7	1	Place Value	2
8	1	Measurement	2
9	1	Multiplication	2
10	1	Division	2
11	1	Geometry	3
12	1	Time & Calendar	3
13	1	Word Problems	3
14	1	Decimals	3
15	1	Data Basics	3
16	1	Area & Perimeter	4
17	1	Data & Graphs	4
18	1	Fractions Advanced	4
19	1	Algebra Basics	4
20	1	Ratio & Proportion	4
21	1	Profit & Loss	5
22	1	Speed & Distance	5
23	1	Statistics	5
24	1	Percentages	5
25	1	Advanced Word Problems	5
26	2	Spelling	1
27	2	Rhyming Words	1
28	2	Alphabet	1
29	2	Nouns	1
30	2	Simple Sentences	1
31	2	Punctuation	2
32	2	Sentences	2
33	2	Simple Grammar	2
34	2	Verbs	2
35	2	Adjectives	2
36	2	Reading Comprehension	3
37	2	Vocabulary	3
38	2	Prepositions	3
39	2	Grammar Basics	3
40	2	Paragraph Writing	3
41	2	Direct & Indirect Speech	4
42	2	Composition	4
43	2	Advanced Grammar	4
44	2	Synonyms & Antonyms	4
45	2	Reading Skills	4
46	2	Figures of Speech	5
47	2	Comprehension Advanced	5
48	2	Creative Writing	5
49	2	Essay Writing	5
50	2	Editing & Proofreading	5
51	3	My Body	1
52	3	Food We Eat	1
53	3	Weather	1
54	3	Plants Around Us	1
55	3	Animals Around Us	1
56	3	Matter & Materials	2
57	3	Light & Shadow	2
58	3	Air & Water	2
59	3	Living and Non-Living	2
60	3	Safety & Health	2
61	3	Ecosystems	3
62	3	Environment	3
63	3	Magnets	3
64	3	Our Earth	3
65	3	Simple Machines	3
66	3	Adaptation	4
67	3	Natural Resources	4
68	3	Simple Machines Advanced	4
69	3	Human Body Systems	4
70	3	Energy Basics	4
71	3	Food Chain	5
72	3	Pollution	5
73	3	Space Exploration	5
74	3	Electricity & Circuits	5
75	3	Climate Change	5
76	4	Animals & Sounds	1
77	4	My Country	1
78	4	Festivals	1
79	4	Colors & Objects	1
80	4	Good Habits	1
81	4	Sports & Games	2
82	4	Famous Places	2
83	4	Transport	2
84	4	Community Helpers	2
85	4	Our Environment	2
86	4	Science & Space Facts	3
87	4	Famous People	3
88	4	National Symbols	3
89	4	World Around Us	3
90	4	Inventions	3
91	4	Awards & Honours	4
92	4	Books & Authors	4
93	4	Current Events	4
94	4	Geography Basics	4
95	4	Indian History Basics	4
96	4	Geography Advanced	5
97	4	Environment & Climate	5
98	4	Technology & Internet	5
99	4	World Records	5
100	4	Global Organisations	5
\.


--
-- Name: game_results_game_result_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('public.game_results_game_result_id_seq', 1, false);


--
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: public; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('public.games_game_id_seq', 1, true);


--
-- Name: admins_admin_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.admins_admin_id_seq', 3, true);


--
-- Name: questions_question_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.questions_question_id_seq', 4678, true);


--
-- Name: results_result_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.results_result_id_seq', 36, true);


--
-- Name: students_student_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.students_student_id_seq', 14, true);


--
-- Name: subjects_subject_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.subjects_subject_id_seq', 4, true);


--
-- Name: topics_topic_id_seq; Type: SEQUENCE SET; Schema: railway; Owner: mindsprouts_user
--

SELECT pg_catalog.setval('railway.topics_topic_id_seq', 100, true);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: game_results game_results_pkey; Type: CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.game_results
    ADD CONSTRAINT game_results_pkey PRIMARY KEY (game_result_id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- Name: games games_topic_id_key; Type: CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_topic_id_key UNIQUE (topic_id);


--
-- Name: admins idx_16484_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.admins
    ADD CONSTRAINT idx_16484_primary PRIMARY KEY (admin_id);


--
-- Name: questions idx_16495_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.questions
    ADD CONSTRAINT idx_16495_primary PRIMARY KEY (question_id);


--
-- Name: results idx_16510_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.results
    ADD CONSTRAINT idx_16510_primary PRIMARY KEY (result_id);


--
-- Name: students idx_16524_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.students
    ADD CONSTRAINT idx_16524_primary PRIMARY KEY (student_id);


--
-- Name: subjects idx_16538_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.subjects
    ADD CONSTRAINT idx_16538_primary PRIMARY KEY (subject_id);


--
-- Name: topics idx_16547_primary; Type: CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.topics
    ADD CONSTRAINT idx_16547_primary PRIMARY KEY (topic_id);


--
-- Name: idx_16484_username; Type: INDEX; Schema: railway; Owner: mindsprouts_user
--

CREATE UNIQUE INDEX idx_16484_username ON railway.admins USING btree (username);


--
-- Name: idx_16495_topic_id; Type: INDEX; Schema: railway; Owner: mindsprouts_user
--

CREATE INDEX idx_16495_topic_id ON railway.questions USING btree (topic_id);


--
-- Name: idx_16510_student_id; Type: INDEX; Schema: railway; Owner: mindsprouts_user
--

CREATE INDEX idx_16510_student_id ON railway.results USING btree (student_id);


--
-- Name: idx_16524_username; Type: INDEX; Schema: railway; Owner: mindsprouts_user
--

CREATE UNIQUE INDEX idx_16524_username ON railway.students USING btree (username);


--
-- Name: idx_16547_subject_id; Type: INDEX; Schema: railway; Owner: mindsprouts_user
--

CREATE INDEX idx_16547_subject_id ON railway.topics USING btree (subject_id);


--
-- Name: game_results game_results_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.game_results
    ADD CONSTRAINT game_results_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(game_id) ON DELETE CASCADE;


--
-- Name: game_results game_results_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.game_results
    ADD CONSTRAINT game_results_student_id_fkey FOREIGN KEY (student_id) REFERENCES railway.students(student_id) ON DELETE CASCADE;


--
-- Name: game_results game_results_topic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.game_results
    ADD CONSTRAINT game_results_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES railway.topics(topic_id) ON DELETE CASCADE;


--
-- Name: games games_topic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mindsprouts_user
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES railway.topics(topic_id) ON DELETE CASCADE;


--
-- Name: questions questions_ibfk_1; Type: FK CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.questions
    ADD CONSTRAINT questions_ibfk_1 FOREIGN KEY (topic_id) REFERENCES railway.topics(topic_id) ON DELETE CASCADE;


--
-- Name: results results_ibfk_1; Type: FK CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.results
    ADD CONSTRAINT results_ibfk_1 FOREIGN KEY (student_id) REFERENCES railway.students(student_id) ON DELETE CASCADE;


--
-- Name: topics topics_ibfk_1; Type: FK CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.topics
    ADD CONSTRAINT topics_ibfk_1 FOREIGN KEY (subject_id) REFERENCES railway.subjects(subject_id) ON DELETE CASCADE;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON SEQUENCES TO mindsprouts_user;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TYPES TO mindsprouts_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON FUNCTIONS TO mindsprouts_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: -; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO mindsprouts_user;


--
-- Name: ai_tutor_sessions; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE IF NOT EXISTS railway.ai_tutor_sessions (
    tutor_session_id text PRIMARY KEY,
    quiz_attempt_id integer NOT NULL,
    student_id integer,
    subject_name text,
    topic_name text,
    score integer NOT NULL,
    total_questions integer NOT NULL,
    performance_summary text NOT NULL,
    pattern_summary text NOT NULL,
    misconception_summary text NOT NULL,
    study_plan_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    context_json jsonb NOT NULL,
    wrong_question_ids_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    unlocked boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.ai_tutor_sessions OWNER TO mindsprouts_user;


--
-- Name: ai_tutor_messages; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE IF NOT EXISTS railway.ai_tutor_messages (
    message_id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tutor_session_id text NOT NULL,
    role text NOT NULL CHECK (role = ANY (ARRAY['assistant'::text, 'user'::text])),
    message_text text NOT NULL,
    meta_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.ai_tutor_messages OWNER TO mindsprouts_user;


--
-- Name: ai_tutor_redemptions; Type: TABLE; Schema: railway; Owner: mindsprouts_user
--

CREATE TABLE IF NOT EXISTS railway.ai_tutor_redemptions (
    redemption_id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    tutor_session_id text NOT NULL,
    question_text text NOT NULL,
    answer_text text NOT NULL,
    student_answer text,
    is_correct boolean,
    awarded_points integer NOT NULL DEFAULT 0,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE railway.ai_tutor_redemptions OWNER TO mindsprouts_user;


--
-- Name: ai_tutor_messages ai_tutor_messages_tutor_session_id_fkey; Type: FK CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.ai_tutor_messages
    ADD CONSTRAINT ai_tutor_messages_tutor_session_id_fkey
    FOREIGN KEY (tutor_session_id) REFERENCES railway.ai_tutor_sessions(tutor_session_id) ON DELETE CASCADE;


--
-- Name: ai_tutor_redemptions ai_tutor_redemptions_tutor_session_id_fkey; Type: FK CONSTRAINT; Schema: railway; Owner: mindsprouts_user
--

ALTER TABLE ONLY railway.ai_tutor_redemptions
    ADD CONSTRAINT ai_tutor_redemptions_tutor_session_id_fkey
    FOREIGN KEY (tutor_session_id) REFERENCES railway.ai_tutor_sessions(tutor_session_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict tu7XTUaOZYFonrTE788UGJabKkFheE1631k92KjO85bM6JOXSVCpYbe1kbUjRvV

