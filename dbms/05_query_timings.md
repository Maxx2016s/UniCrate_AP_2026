# Query Performance Timings

## Benchmark Setup

- Database: PostgreSQL
- Dataset: 1,000 users and 50,000 parcels
- Each query was executed 3 times.
- Average execution time is calculated from the three runs.
- Execution times are in milliseconds (ms).
- Write queries were executed inside transactions and rolled back to avoid permanent data changes.
- Query execution plans were captured using `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`.

## Query Timings

| Query | Type | Description | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan Type / Main Plan |
|---|---|---|---:|---:|---:|---:|---|
| Q1 | READ | Count total users | 0.438 | 0.091 | 0.088 | 0.206 | Sequential Scan on users |
| Q2 | READ | Find user by email | 0.102 | 0.020 | 0.019 | 0.047 | Index Scan on users_email_key |
| Q3 | READ | Find user by registration number | 0.068 | 0.008 | 0.007 | 0.028 | Index Scan on idx_users_registration_number |
| Q4 | READ | Find user by primary key | 0.038 | 0.005 | 0.005 | 0.016 | Index Scan on users_pkey |
| Q5 | WRITE | Insert a new user | 1.269 | 0.181 | 0.158 | 0.536 | INSERT |
| Q6 | WRITE | Insert a new parcel | 0.616 | 0.223 | 0.194 | 0.344 | INSERT |
| Q7 | READ | Retrieve parcels using status and filters | 25.753 | 14.974 | 15.526 | 18.751 | Bitmap Heap Scan, Merge Joins, Sort |
| Q8 | READ | Retrieve parcels by student registration number | 0.066 | 0.056 | 0.053 | 0.058 | Bitmap Heap Scan, Merge Joins, Sort |
| Q9 | READ | Retrieve parcel by ID | 0.028 | 0.019 | 0.019 | 0.022 | Index Scan on parcels_pkey |
| Q10 | READ | Retrieve one parcel by ID and student registration number | — | — | — | — | To be measured |
| Q11 | READ | Check whether a parcel exists and retrieve its status | — | — | — | — | To be measured |
| Q12 | WRITE | Update parcel details | — | — | — | — | To be measured |
| Q13 | WRITE | Mark a pending parcel as collected | — | — | — | — | To be measured |
| Q14 | WRITE | Delete a parcel by ID | — | — | — | — | To be measured |
| Q15 | READ | Retrieve overall dashboard parcel statistics | — | — | — | — | To be measured |
| Q16 | READ | Retrieve dashboard statistics for a student | — | — | — | — | To be measured |
| Q17 | READ | Retrieve the five most recent parcels for staff dashboard | — | — | — | — | To be measured |
| Q18 | READ | Retrieve the five most recent parcels for student dashboard | — | — | — | — | To be measured |

## Execution Plans

Raw execution plans are stored in the `dbms/plans/` directory.

Each query has three execution plan files, one for each run:

- `Q1_run1.txt` through `Q9_run3.txt`
- `Q10_run1.txt` through `Q18_run3.txt` (to be added after benchmarking)

## Notes

- Q7 had the highest average execution time among Q1–Q9.
- Q2, Q3, Q4, and Q9 benefited from index scans.
- Q1 used a sequential scan to count users.
- Write queries were rolled back after measurement to preserve the dataset.
- Q10–Q18 timings and execution plans must be added after their three benchmark runs are completed.
