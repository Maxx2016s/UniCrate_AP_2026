-- =========================================================
-- Instagram Social Media Database
-- File: sql/01_schema.sql
-- Purpose: Create the relational schema for the project
-- =========================================================

-- Create and select the project schema
CREATE SCHEMA IF NOT EXISTS instagram;
SET search_path TO instagram;

-- 1. USERS
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(150),
    email VARCHAR(255) UNIQUE,
    bio TEXT,
    account_type VARCHAR(20) NOT NULL,
    is_private BOOLEAN NOT NULL,
    is_verified BOOLEAN NOT NULL,
    followers_count INTEGER NOT NULL DEFAULT 0,
    following_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT chk_users_account_type
        CHECK (account_type IN ('BUSINESS', 'CREATOR', 'PERSONAL')),

    CONSTRAINT chk_users_followers
        CHECK (followers_count >= 0),

    CONSTRAINT chk_users_following
        CHECK (following_count >= 0)
);


-- 2. FOLLOWS
CREATE TABLE follows (
    follower_id INTEGER NOT NULL,
    followee_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (follower_id, followee_id),

    CONSTRAINT fk_follows_follower
        FOREIGN KEY (follower_id) REFERENCES users(user_id),

    CONSTRAINT fk_follows_followee
        FOREIGN KEY (followee_id) REFERENCES users(user_id),

    CONSTRAINT chk_follows_status
        CHECK (status IN ('ACCEPTED', 'PENDING')),

    CONSTRAINT chk_follows_not_self
        CHECK (follower_id <> followee_id)
);


-- 3. HASHTAGS
CREATE TABLE hashtags (
    hashtag_id INTEGER PRIMARY KEY,
    tag VARCHAR(255) NOT NULL UNIQUE
);


-- 4. POSTS
CREATE TABLE posts (
    post_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    post_type VARCHAR(20) NOT NULL,
    caption TEXT,
    location_name VARCHAR(255),
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_posts_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT chk_posts_type
        CHECK (post_type IN ('CAROUSEL', 'PHOTO', 'REEL', 'VIDEO')),

    CONSTRAINT chk_posts_like_count
        CHECK (like_count >= 0),

    CONSTRAINT chk_posts_comment_count
        CHECK (comment_count >= 0)
);


-- 5. POST_HASHTAGS
CREATE TABLE post_hashtags (
    post_id INTEGER NOT NULL,
    hashtag_id INTEGER NOT NULL,

    PRIMARY KEY (post_id, hashtag_id),

    CONSTRAINT fk_post_hashtags_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id),

    CONSTRAINT fk_post_hashtags_hashtag
        FOREIGN KEY (hashtag_id) REFERENCES hashtags(hashtag_id)
);


-- 6. POST_MEDIA
CREATE TABLE post_media (
    post_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    media_url TEXT NOT NULL,
    width INTEGER,
    height INTEGER,
    duration_sec NUMERIC(10,2),

    PRIMARY KEY (post_id, position),

    CONSTRAINT fk_post_media_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id),

    CONSTRAINT chk_post_media_type
        CHECK (media_type IN ('IMAGE', 'VIDEO')),

    CONSTRAINT chk_post_media_position
        CHECK (position > 0),

    CONSTRAINT chk_post_media_width
        CHECK (width IS NULL OR width > 0),

    CONSTRAINT chk_post_media_height
        CHECK (height IS NULL OR height > 0),

    CONSTRAINT chk_post_media_duration
        CHECK (duration_sec IS NULL OR duration_sec >= 0)
);


-- 7. LIKES
CREATE TABLE likes (
    user_id INTEGER NOT NULL,
    post_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (user_id, post_id),

    CONSTRAINT fk_likes_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT fk_likes_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id)
);


-- 8. COMMENTS
CREATE TABLE comments (
    comment_id INTEGER PRIMARY KEY,
    post_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    parent_comment_id INTEGER,
    body TEXT NOT NULL,
    is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_comments_post
        FOREIGN KEY (post_id) REFERENCES posts(post_id),

    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT fk_comments_parent
        FOREIGN KEY (parent_comment_id) REFERENCES comments(comment_id),

    CONSTRAINT chk_comments_not_self_parent
        CHECK (parent_comment_id IS NULL OR parent_comment_id <> comment_id)
);


-- 9. STORIES
CREATE TABLE stories (
    story_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    media_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    view_count INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT fk_stories_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),

    CONSTRAINT chk_stories_media_type
        CHECK (media_type IN ('IMAGE', 'VIDEO')),

    CONSTRAINT chk_stories_view_count
        CHECK (view_count >= 0),

    CONSTRAINT chk_stories_expiry
        CHECK (expires_at > created_at)
);
