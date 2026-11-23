-- =========================================================
-- UniCrate University Parcel Management System
-- File: dbms/03_schema.sql
-- Purpose: Create the relational schema for the project
--
-- This is the relational form of backend/prisma/schema.prisma
-- in the main UniCrate repo (users, parcels, Role and
-- ParcelStatus). The live app stores the same data in
-- MongoDB Atlas through Prisma.
--
-- Differences caused by moving from MongoDB to SQL:
--   * Mongo's ObjectId (_id) becomes an integer identity column.
--   * Prisma enums (Role, ParcelStatus) become VARCHAR + CHECK.
--   * camelCase field names become snake_case column names.
-- =========================================================

-- Create and select the project schema
CREATE SCHEMA IF NOT EXISTS unicrate;
SET search_path TO unicrate;

-- 1. USERS
-- Staff (ADMIN, EDITOR) and students (VIEWER) who can log in.
CREATE TABLE users (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,          -- bcrypt hash, never the plain password
    registration_number VARCHAR(50),         -- required for VIEWER, optional for staff
    role VARCHAR(10) NOT NULL DEFAULT 'VIEWER',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_users_role
        CHECK (role IN ('ADMIN', 'EDITOR', 'VIEWER')),

    -- The app rejects a VIEWER account without a registration number
    CONSTRAINT chk_users_viewer_reg_no
        CHECK (role <> 'VIEWER' OR registration_number IS NOT NULL),

    -- The app trims and uppercases registration numbers before saving
    CONSTRAINT chk_users_reg_no_format
        CHECK (registration_number IS NULL
               OR (registration_number <> ''
                   AND registration_number = UPPER(BTRIM(registration_number)))),

    -- Same pattern the app uses: /^\S+@\S+\.\S+$/
    CONSTRAINT chk_users_email_format
        CHECK (email ~ '^\S+@\S+\.\S+$')
);


-- 2. PARCELS
-- One row per parcel that arrives at the university.
CREATE TABLE parcels (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tracking_id VARCHAR(30) NOT NULL UNIQUE,   -- e.g. UC-20261119-A7F3K2
    student_name VARCHAR(150) NOT NULL,
    student_registration_number VARCHAR(50) NOT NULL,
    student_email VARCHAR(255) NOT NULL,
    courier_name VARCHAR(150) NOT NULL,
    description TEXT,
    arrival_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    collected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Staff member who registered the parcel
    registered_by_id INTEGER NOT NULL,

    -- Staff member who marked it collected (set by PATCH /:id/collect)
    collected_by_id INTEGER,

    CONSTRAINT fk_parcels_registered_by
        FOREIGN KEY (registered_by_id) REFERENCES users(id),

    CONSTRAINT fk_parcels_collected_by
        FOREIGN KEY (collected_by_id) REFERENCES users(id),

    CONSTRAINT chk_parcels_status
        CHECK (status IN ('PENDING', 'COLLECTED')),

    -- A collected parcel always records when and by whom.
    -- A pending parcel never has collection details.
    CONSTRAINT chk_parcels_collection
        CHECK (
            (status = 'PENDING'
                AND collected_at IS NULL
                AND collected_by_id IS NULL)
            OR
            (status = 'COLLECTED'
                AND collected_at IS NOT NULL
                AND collected_by_id IS NOT NULL)
        ),

    -- The app trims and uppercases registration numbers before saving
    CONSTRAINT chk_parcels_reg_no_format
        CHECK (student_registration_number <> ''
               AND student_registration_number = UPPER(BTRIM(student_registration_number))),

    CONSTRAINT chk_parcels_email_format
        CHECK (student_email ~ '^\S+@\S+\.\S+$')
);


-- 3. INDEXES
-- The same indexes as schema.prisma. The queries in 04_queries.sql rely on them.
-- (users.email and parcels.tracking_id already get a unique index from UNIQUE.)

-- Registration numbers are NOT unique in the database, because staff accounts
-- have none. The app checks uniqueness for students instead (see Q3).
CREATE INDEX idx_users_registration_number
    ON users (registration_number);

CREATE INDEX idx_parcels_student_registration_number
    ON parcels (student_registration_number);

CREATE INDEX idx_parcels_status
    ON parcels (status);