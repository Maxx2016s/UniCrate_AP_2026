# Query Timings and Execution Plans (CP4)

Execution times are in milliseconds (ms). Each query was executed three times using `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`.

| Query | Type | What it does | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan type / main plan |
|---|---|---|---:|---:|---:|---:|---|
| Q1 | READ | Count all users | 0.438 | 0.091 | 0.088 | 0.206 | Sequential Scan (`users`) |
| Q2 | READ | Find user by email | 0.102 | 0.020 | 0.019 | 0.047 | Index Scan (`users_email_key`) |
| Q3 | READ | Find user by registration number | 0.068 | 0.008 | 0.007 | 0.028 | Index Scan (`idx_users_registration_number`) |
| Q4 | READ | Load user by ID | 0.038 | 0.005 | 0.005 | 0.016 | Index Scan (`users_pkey`) |
| Q5 | WRITE | Create a user | 1.269 | 0.181 | 0.158 | 0.536 | INSERT |
| Q6 | WRITE | Register a parcel | 0.616 | 0.223 | 0.194 | 0.344 | INSERT |
| Q7 | READ | Staff parcel list with status/search filters and user joins | 25.753 | 14.974 | 15.526 | 18.751 | Bitmap Heap Scan, Merge Joins, Sort |
| Q8 | READ | Student parcel list restricted to their registration number | 0.066 | 0.056 | 0.053 | 0.058 | Bitmap Heap Scan |
| Q9 | READ | Get one parcel by ID for staff | 0.028 | 0.019 | 0.019 | 0.022 | Index Scan (`parcels_pkey`), Merge Joins |
| Q10 | READ | Get one parcel by ID for a student, restricted to their registration number | — | — | — | — | Teammate to fill |
| Q11 | READ | Check parcel existence and read its status | — | — | — | — | Teammate to fill |
| Q12 | WRITE | Update editable parcel fields | — | — | — | — | Teammate to fill |
| Q13 | WRITE | Mark a pending parcel as collected | — | — | — | — | Teammate to fill |
| Q14 | WRITE | Delete a parcel | — | — | — | — | Teammate to fill |
| Q15 | READ | Dashboard counts for staff | — | — | — | — | Teammate to fill |
| Q16 | READ | Dashboard counts for a student's own parcels | — | — | — | — | Teammate to fill |
| Q17 | READ | Five most recent parcels for staff dashboard | — | — | — | — | Teammate to fill |
| Q18 | READ | Five most recent parcels for student dashboard | — | — | — | — | Teammate to fill |

## Execution plans

Q1–Q9: `dbms/plans/Q1_run1.txt` through `dbms/plans/Q9_run3.txt`.

Q10–Q18: Add three plan files per query using the same naming pattern, for example `Q10_run1.txt`, `Q10_run2.txt`, `Q10_run3.txt`.
