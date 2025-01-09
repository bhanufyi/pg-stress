-- 1) Create the 'users' table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL
);

-- 2) Insert two sample entries
INSERT INTO users (name, email)
VALUES 
  ('John', 'john@example.com'),
  ('Jane', 'jane@example.com');
