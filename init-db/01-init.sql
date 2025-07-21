-- Initial database setup script
-- This script runs automatically when PostgreSQL container starts for the first time

-- Create a sample schema
CREATE SCHEMA IF NOT EXISTS sample;

-- Create a sample table with some data
CREATE TABLE IF NOT EXISTS sample.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Insert sample data
INSERT INTO sample.users (username, email) VALUES 
    ('john_doe', 'john@example.com'),
    ('jane_smith', 'jane@example.com'),
    ('bob_johnson', 'bob@example.com'),
    ('alice_williams', 'alice@example.com')
ON CONFLICT (username) DO NOTHING;

-- Create another sample table
CREATE TABLE IF NOT EXISTS sample.posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES sample.users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample posts
INSERT INTO sample.posts (user_id, title, content) VALUES 
    (1, 'First Post', 'This is my first post on the platform!'),
    (1, 'PostgreSQL Tips', 'Here are some useful PostgreSQL tips and tricks.'),
    (2, 'Hello World', 'Just saying hello to everyone.'),
    (3, 'Database Design', 'Some thoughts on database design principles.'),
    (4, 'Welcome', 'Welcome to our new platform!')
ON CONFLICT DO NOTHING;

-- Create an index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_email ON sample.users(email);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON sample.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON sample.posts(created_at);

-- Create a view for easier querying
CREATE OR REPLACE VIEW sample.user_posts AS
SELECT 
    u.username,
    u.email,
    p.title,
    p.content,
    p.created_at as post_created_at
FROM sample.users u
LEFT JOIN sample.posts p ON u.id = p.user_id
ORDER BY p.created_at DESC;
