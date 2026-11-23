# UniCrate – CP4 Query Timing Report

## 1. Benchmark Environment

- **Database:** PostgreSQL
- **Database name:** `unicrate`
- **Schema:** `unicrate`
- **Users:** 1,000
- **Parcels:** 50,000
- **Queries:** Q1–Q18
- **Runs per query:** 3
- **Measurement:** `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)`
- **Timing unit:** milliseconds (ms)

## 2. Methodology

Each query was executed three times using PostgreSQL's `EXPLAIN ANALYZE`.

The `Execution Time` value at the bottom of each query plan was recorded.

The average execution time was calculated as:

\[
\text{Average} = \frac{\text{Run 1}+\text{Run 2}+\text{Run 3}}{3}
\]

Write queries (Q5, Q6, Q12, Q13 and Q14) were executed inside transactions using `BEGIN` and `ROLLBACK` to prevent permanent data changes.

## 3. Query Timing Results

| Query | Description | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---|---:|---:|---:|---:|
| Q1 | Count users | READ | 0.438 | 0.091 | 0.088 | 0.206 |
| Q2 | Find user by email | READ | 0.102 | 0.020 | 0.019 | 0.047 |
| Q3 | Find user by registration number | READ | 0.068 | 0.008 | 0.007 | 0.028 |
| Q4 | Load logged-in user by ID | READ | 0.038 | 0.005 | 0.005 | 0.016 |
| Q5 | Create a user | WRITE | 1.269 | 0.181 | 0.158 | 0.536 |
| Q6 | Register a parcel | WRITE | 0.616 | 0.223 | 0.194 | 0.344 |
| Q7 | List all parcels with search and status filter (staff) | READ | 25.753 | 14.974 | 15.526 | 18.751 |
| Q8 | List parcels for a student | READ | 0.066 | 0.056 | 0.053 | 0.058 |
| Q9 | Get one parcel by ID (staff) | READ | 0.028 | 0.019 | 0.019 | 0.022 |
| Q10 | Get one parcel by ID (student) | READ | 0.182 | 0.177 | 0.276 | 0.212 |
| Q11 | Check parcel existence and status | READ | 0.066 | 0.093 | 0.097 | 0.085 |
| Q12 | Update editable parcel fields | WRITE | 1.371 | 0.633 | 0.455 | 0.820 |
| Q13 | Mark a parcel as collected | WRITE | 1.599 | 1.574 | 2.146 | 1.773 |
| Q14 | Delete a parcel | WRITE | 0.138 | 0.265 | 0.279 | 0.227 |
| Q15 | Dashboard counts (staff) | READ | 10.402 | 10.843 | 11.060 | 10.768 |
| Q16 | Dashboard counts (student) | READ | 0.892 | 0.420 | 0.389 | 0.567 |
| Q17 | Five most recent parcels (staff) | READ | 34.722 | 33.292 | 32.557 | 33.524 |
| Q18 | Five most recent parcels (student) | READ | 0.502 | 0.335 | 0.581 | 0.473 |

## 4. Query Execution Plan Observations

The following scan and execution strategies were observed in the PostgreSQL query plans.

| Query | Observed execution strategy |
|---|---|
| Q1 | Sequential Scan on users followed by Aggregate |
| Q2 | Index Scan using `users_email_key` |
| Q3 | Index Scan using `idx_users_registration_number` |
| Q4 | Index Scan using `users_pkey` |
| Q5 | INSERT |
| Q6 | INSERT |
| Q7 | Bitmap Heap Scan using `idx_parcels_status`, joins and sorting |
| Q8 | Bitmap Heap Scan using `idx_parcels_student_registration_number`, joins and sorting |
| Q9 | Index Scan using `parcels_pkey`, joins and sorting |
| Q10 | Index Scan using `parcels_pkey`, joins with users |
| Q11 | Index Scan using `parcels_pkey` |
| Q12 | UPDATE using Index Scan on `parcels_pkey` |
| Q13 | UPDATE using Index Scan on `parcels_pkey`, with status filter |
| Q14 | DELETE using Index Scan on `parcels_pkey` |
| Q15 | Index Only Scan using `idx_parcels_status`, followed by Aggregate |
| Q16 | Bitmap Index Scan and Bitmap Heap Scan using `idx_parcels_student_registration_number`, followed by Aggregate |
| Q17 | Sequential Scans, Hash Joins and top-N heapsort |
| Q18 | Bitmap Index Scan and Bitmap Heap Scan using `idx_parcels_student_registration_number`, joins and top-N heapsort |

## 5. Key Observations

1. **Q17 has the highest average execution time (33.524 ms).** It retrieves the five most recent parcels for staff and processes the parcel and user tables using joins and sorting.

2. **Q7 is another relatively expensive query (18.751 ms).** It supports staff parcel listing with optional search and status filters.

3. **Q15 takes 10.768 ms.** The staff dashboard aggregation processes all 50,000 parcels.

4. **Student-specific queries benefit from filtering by registration number.** Q16 and Q18 use the `idx_parcels_student_registration_number` index.

5. **Primary-key lookups are fast.** Q4, Q9 and Q11 use primary-key indexes to retrieve records.

6. **Write operations were measured safely.** Q5, Q6, Q12, Q13 and Q14 were rolled back after measurement.

## 6. Conclusion

The benchmark shows that indexed lookups and student-specific queries generally execute quickly. Queries involving large result sets, joins, aggregations and sorting take comparatively longer.

The execution plans help identify where indexes are being used and where query optimization may be beneficial.

**Note:** The timings represent measurements from the local PostgreSQL benchmark environment and may vary with cache state, system load and database configuration.
