-- dbms/04_queries.sql
-- UniCrate: every query the application uses, expressed as SQL.
-- Each query is marked -- READ or -- WRITE.
-- "?" marks a value supplied by the app (parameterized, never string-built).
--
-- Table shapes (relational form of prisma/schema.prisma, created in 03_schema.sql):
--   users   (id, name, email UNIQUE, password, registration_number, role,
--            created_at, updated_at)
--   parcels (id, tracking_id UNIQUE, student_name, student_registration_number,
--            student_email, courier_name, description, arrival_date, status,
--            collected_at, created_at, updated_at,
--            registered_by_id -> users.id, collected_by_id -> users.id)
--
-- Indexes the queries rely on:
--   users(email) UNIQUE, users(registration_number),
--   parcels(tracking_id) UNIQUE, parcels(student_registration_number),
--   parcels(status)


/* =====================================================================
   AUTH  (authController.js, authMiddleware.js, authRoutes.js)
   ===================================================================== */

-- Q1: Count users (first-ADMIN check in registerGate and register;
--     also getSetupStatus, which shows first-admin setup only when this is 0)
-- READ
SELECT COUNT(*) AS user_count
FROM users;

-- Q2: Find user by email (login; duplicate-email check on register)
-- READ
SELECT id, name, email, password, registration_number, role
FROM users
WHERE email = ?;

-- Q3: Find user by registration number (duplicate check on register)
-- READ
SELECT id
FROM users
WHERE registration_number = ?
LIMIT 1;

-- Q4: Load logged-in user by id, password excluded (authMiddleware protect)
-- READ
SELECT id, name, email, registration_number, role
FROM users
WHERE id = ?;

-- Q5: Create a user (register)
-- WRITE
INSERT INTO users (name, email, password, registration_number, role, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, NOW(), NOW());


/* =====================================================================
   PARCELS  (parcelController.js)
   ===================================================================== */

-- Q6: Register a parcel (createParcel)
-- WRITE
INSERT INTO parcels (
  tracking_id, student_name, student_registration_number, student_email,
  courier_name, description, arrival_date, status,
  registered_by_id, created_at, updated_at
)
VALUES (?, ?, ?, ?, ?, ?, COALESCE(?, NOW()), 'PENDING', ?, NOW(), NOW());

-- Q7: List all parcels with search and status filter, staff view (getParcels)
--     JOINs bring in who registered and who collected each parcel.
--     Optional filters: pass NULL to skip status or search.
-- READ
SELECT p.id, p.tracking_id, p.student_name, p.student_registration_number,
       p.student_email, p.courier_name, p.description, p.arrival_date,
       p.status, p.collected_at, p.created_at,
       rb.id   AS registered_by_id,   rb.name AS registered_by_name,
       rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.id   AS collected_by_id,    cb.name AS collected_by_name,
       cb.email AS collected_by_email, cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
WHERE (? IS NULL OR p.status = ?)
  AND (? IS NULL
       OR LOWER(p.tracking_id)                  LIKE LOWER(CONCAT('%', ?, '%'))
       OR LOWER(p.student_name)                 LIKE LOWER(CONCAT('%', ?, '%'))
       OR LOWER(p.student_registration_number)  LIKE LOWER(CONCAT('%', ?, '%')))
ORDER BY p.created_at DESC;

-- Q8: List parcels, student (VIEWER) view. The registration number comes from
--     the logged-in user's record, never from the request (privacy rule).
-- READ
SELECT p.id, p.tracking_id, p.student_name, p.student_registration_number,
       p.student_email, p.courier_name, p.description, p.arrival_date,
       p.status, p.collected_at, p.created_at,
       rb.id   AS registered_by_id,   rb.name AS registered_by_name,
       rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.id   AS collected_by_id,    cb.name AS collected_by_name,
       cb.email AS collected_by_email, cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
WHERE p.student_registration_number = ?          -- req.user.registrationNumber
  AND (? IS NULL OR p.status = ?)
  AND (? IS NULL
       OR LOWER(p.tracking_id)                  LIKE LOWER(CONCAT('%', ?, '%'))
       OR LOWER(p.student_name)                 LIKE LOWER(CONCAT('%', ?, '%'))
       OR LOWER(p.student_registration_number)  LIKE LOWER(CONCAT('%', ?, '%')))
ORDER BY p.created_at DESC;

-- Q9: Get one parcel by id, staff (getParcelById)
-- READ
SELECT p.*,
       rb.name AS registered_by_name, rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.name AS collected_by_name,  cb.email AS collected_by_email,  cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
WHERE p.id = ?;

-- Q10: Get one parcel by id, student. A parcel that belongs to someone else
--      returns no row, so the app answers 404 and hides that it exists.
-- READ
SELECT p.*,
       rb.name AS registered_by_name, rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.name AS collected_by_name,  cb.email AS collected_by_email,  cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
WHERE p.id = ?
  AND p.student_registration_number = ?;         -- req.user.registrationNumber

-- Q11: Check a parcel exists and read its status (updateParcel, collectParcel,
--      deleteParcel all run this before changing anything)
-- READ
SELECT id, status
FROM parcels
WHERE id = ?;

-- Q12: Update editable parcel fields (updateParcel).
--      Only fields sent by the client are changed; status, tracking_id and
--      collection details are never touched here.
--      description can be cleared (set to NULL), so a flag says whether the
--      client sent it: first ? = TRUE if sent, second ? = the new value.
-- WRITE
UPDATE parcels
SET student_name                = COALESCE(?, student_name),
    student_registration_number = COALESCE(?, student_registration_number),
    student_email               = COALESCE(?, student_email),
    courier_name                = COALESCE(?, courier_name),
    description                 = CASE WHEN ? THEN ? ELSE description END,
    arrival_date                = COALESCE(?, arrival_date),
    updated_at                  = NOW()
WHERE id = ?;

-- Q13: Mark a parcel collected (collectParcel). The status guard makes a
--      second collect update 0 rows, which the app reports as 409.
-- WRITE
UPDATE parcels
SET status          = 'COLLECTED',
    collected_at    = NOW(),
    collected_by_id = ?,                         -- req.user.id
    updated_at      = NOW()
WHERE id = ?
  AND status = 'PENDING';

-- Q14: Delete a parcel, ADMIN only (deleteParcel)
-- WRITE
DELETE FROM parcels
WHERE id = ?;


/* =====================================================================
   DASHBOARD  (getParcelStats)
   ===================================================================== */

-- Q15: Dashboard counts, staff. One pass over the table instead of three.
-- READ
SELECT COUNT(*)                                          AS total,
       COALESCE(SUM(CASE WHEN status = 'PENDING'   THEN 1 ELSE 0 END), 0) AS pending,
       COALESCE(SUM(CASE WHEN status = 'COLLECTED' THEN 1 ELSE 0 END), 0) AS collected
FROM parcels;

-- Q16: Dashboard counts, student (own parcels only)
-- READ
SELECT COUNT(*)                                          AS total,
       COALESCE(SUM(CASE WHEN status = 'PENDING'   THEN 1 ELSE 0 END), 0) AS pending,
       COALESCE(SUM(CASE WHEN status = 'COLLECTED' THEN 1 ELSE 0 END), 0) AS collected
FROM parcels
WHERE student_registration_number = ?;

-- Q17: Five most recent parcels for the dashboard, staff
-- READ
SELECT p.id, p.tracking_id, p.student_name, p.student_registration_number,
       p.courier_name, p.status, p.created_at,
       rb.id AS registered_by_id, rb.name AS registered_by_name,
       rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.id AS collected_by_id, cb.name AS collected_by_name,
       cb.email AS collected_by_email, cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
ORDER BY p.created_at DESC
LIMIT 5;

-- Q18: Five most recent parcels for the dashboard, student
-- READ
SELECT p.id, p.tracking_id, p.student_name, p.student_registration_number,
       p.courier_name, p.status, p.created_at,
       rb.id AS registered_by_id, rb.name AS registered_by_name,
       rb.email AS registered_by_email, rb.role AS registered_by_role,
       cb.id AS collected_by_id, cb.name AS collected_by_name,
       cb.email AS collected_by_email, cb.role AS collected_by_role
FROM parcels p
JOIN users rb       ON rb.id = p.registered_by_id
LEFT JOIN users cb  ON cb.id = p.collected_by_id
WHERE p.student_registration_number = ?
ORDER BY p.created_at DESC
LIMIT 5;
