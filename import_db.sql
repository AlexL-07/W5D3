PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
    );

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    associated_author INTEGER NOT NULL,

    FOREIGN KEY (associated_author) REFERENCES users(id)
);

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL, 
    question_id INTEGER NOT NULL, 

    FOREIGN KEY (user_id) REFERENCES users(id)
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL, 
    question_id INTEGER NOT NULL,
    reply_id INTEGER,
    body TEXT NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
    FOREIGN KEY (question_id) REFERENCES questions(id)
    FOREIGN KEY (reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    liked BOOLEAN,
    user_id INTEGER NOT NULL, 
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO users (fname, lname)
VALUES 
    ('Alex', 'Luong'),
    ('Chad', 'Fitzgerald');

INSERT INTO questions (title, body, associated_author)
VALUES
    ('first question', 'body', (SELECT id FROM users WHERE fname = 'Alex' AND lname = 'Luong'));

INSERT INTO question_follows (user_id, question_id)
VALUES
    ((SELECT id FROM users WHERE fname = 'Alex' AND lname = 'Luong'), (SELECT id FROM questions WHERE title = 'first question'));

INSERT INTO replies (user_id, question_id, reply_id, body)
VALUES
    ((SELECT id FROM users WHERE fname = 'Alex' AND lname = 'Luong'), 
    (SELECT id FROM questions WHERE title = 'first question'), 
    (SELECT id FROM replies WHERE id = 1),
    'body');

INSERT INTO question_likes (liked, user_id, question_id)
VALUES
    (1, 
    (SELECT id FROM users WHERE fname = 'Alex' AND lname = 'Luong'), 
    (SELECT id FROM questions WHERE title = 'first question'));

