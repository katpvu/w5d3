PRAGMA foreign_keys = ON;

DROP TABLE question_follows;
DROP TABLE question_likes;
DROP TABLE replies;
DROP TABLE questions;
DROP TABLE users;


CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id integer NOT NULL,
    question_id integer NOT NULL
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    reply_id INTEGER REFERENCES replies(id),
    
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    question_like INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);


INSERT INTO
    users (fname, lname)
VALUES
    ('deric', 'lee'),
    ('kat', 'vu');

INSERT INTO
    questions (title, body, user_id)
VALUES
    ('SQL', 'How to create a create a table?', (SELECT id FROM users WHERE fname = 'kat' AND lname = 'vu')),
    ('Ruby', 'How to flatten recursively?', (SELECT id FROM users WHERE fname = 'deric' AND lname = 'lee'));

INSERT INTO
    question_follows (user_id, question_id)
VALUES
    (1, 1),
    (2, 1),
    (2, 2);

INSERT INTO 
    replies (body, question_id, user_id, reply_id)
VALUES
    ("response_1", 1, 1, NULL),
    ("response_2", 1, 1, 1),
    ("response_3", 1, 1, 2),
    ("response_4", 1, 2, 2),
    ("response_5", 2, 2, NULL);

INSERT INTO
    question_likes (question_like, user_id, question_id)
VALUES
    (true, 1, 1),
    (true, 2, 1),
    (true, 2, 2);
