-- =========================================================
-- UniCrate Parcel Management Database
-- File: dbms/04_queries.sql
-- Purpose: Application query catalogue
-- Note: PostgreSQL academic representation; runtime uses Prisma
-- READ = retrieval; WRITE = insert, update, or delete
-- Named placeholders (e.g. :email) are supplied by the API
-- =========================================================


-- =========================================================
-- 1. AUTHENTICATION / USER MANAGEMENT
-- =========================================================

-- READ: Find an account by email during login.
-- The application compares the submitted password using bcrypt.
SELECT id, name, email, password, registration_number, role
FROM users
WHERE LOWER(email) = LOWER(:email);


-- READ: Get the authenticated user's profile.
-- Do not return the password field in the API response.
SELECT id, name, email, registration_number, role, created_at, updated_at
FROM users
WHERE id = :authenticated_user_id;


-- READ: Check whether an email is already registered.
SELECT id
FROM users
WHERE LOWER(email) = LOWER(:email);


-- READ: Check registration-number duplicates in application logic.
-- The database index is not a UNIQUE constraint.
SELECT id
FROM users
WHERE UPPER(TRIM(registration_number)) = UPPER(TRIM(:registration_number));


-- WRITE: Create a user.
-- Hash the password and validate role permissions in the controller.
INSERT INTO users (
    id, name, email, password, registration_number, role
)
VALUES (
    :object_id,
    :name,
    LOWER(:email),
    :bcrypt_hash,
    NULLIF(UPPER(TRIM(:registration_number)), ''),
    :role
)
RETURNING id, name, email, registration_number, role, created_at;


-- READ: List users for an authorized administrator.
SELECT id, name, email, registration_number, role, created_at
FROM users
ORDER BY created_at DESC;


-- =========================================================
-- 2. PARCEL REGISTRATION / LISTING / DETAILS
-- =========================================================

-- WRITE: Register an incoming parcel.
-- Student and courier details are stored directly on the parcel.
INSERT INTO parcels (
    id,
    tracking_id,
    student_name,
    student_registration_number,
    student_email,
    courier_name,
    description,
    arrival_date,
    status,
    registered_by_id
)
VALUES (
    :object_id,
    :tracking_id,
    :student_name,
    UPPER(TRIM(:student_registration_number)),
    LOWER(:student_email),
    :courier_name,
    :description,
    COALESCE(:arrival_date, CURRENT_TIMESTAMP),
    'PENDING',
    :authenticated_staff_user_id
)
RETURNING *;


-- READ: List all parcels for authorized staff.
-- Join users twice to get the registering and collecting staff names.
SELECT
    p.*,
    registrar.name AS registered_by_name,
    collector.name AS collected_by_name
FROM parcels p
JOIN users registrar
    ON registrar.id = p.registered_by_id
LEFT JOIN users collector
    ON collector.id = p.collected_by_id
ORDER BY p.arrival_date DESC;


-- READ: List parcels belonging to the authenticated student.
-- The registration number must come from the authenticated user,
-- not from an untrusted client-supplied value.
SELECT
    id, tracking_id, student_name, student_registration_number,
    student_email, courier_name, description, arrival_date,
    status, collected_at
FROM parcels
WHERE student_registration_number = :authenticated_user_registration_number
ORDER BY arrival_date DESC;


-- READ: Get one parcel by ID.
-- If the requester is a VIEWER, the application must additionally
-- restrict the result to that user's registration number.
SELECT
    p.*,
    registrar.name AS registered_by_name,
