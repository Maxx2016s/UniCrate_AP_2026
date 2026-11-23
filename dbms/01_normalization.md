# Normalization 
 
## 1. What is Normalization?
 
Normalization is a way of organizing data in a database so that we do not store the same information unnecessarily in many places. It helps reduce data duplication and avoids problems when inserting, updating, or deleting records.
 
For our UniCrate database, we have two tables: `users` (staff and students who can log in) and `parcels` (every parcel that arrives at the university). In this document, I have explained how the schema follows the normal forms we have studied: 1NF, 2NF, 3NF, and BCNF.
 
The tables are defined in `dbms/03_schema.sql`. They are the relational form of the `User` and `Parcel` models in `backend/prisma/schema.prisma` in the main UniCrate repo.
 
## 2. First Normal Form (1NF)
 
A table is in First Normal Form when:
 
- Each column contains a single, atomic value.
- There are no lists or multiple values stored in one cell.
- Each row can be uniquely identified.
### How it applies to our database
 
A staff member can register many parcels, and a parcel is registered by exactly one staff member. If we stored all the parcels of a staff member inside the `users` table as a list, that column would contain multiple values and would not follow 1NF.
 
An example of a table that is not in 1NF:
 
| id | name | role | parcels_registered |
|---|---|---|---|
| 1 | Admin | ADMIN | UC-20261119-A7F3K2, UC-20261120-B8K4M3 |
 
To avoid this, we keep the parcels in their own table:
 
- `users` stores one row per account.
- `parcels` stores one row per parcel.
- `parcels.registered_by_id` points to the staff member who registered the parcel (many parcels, one user).
- `parcels.collected_by_id` points to the staff member who marked the parcel as collected (many parcels, one user, or empty while the parcel is pending).
Every row in both tables is identified by its `id`. The `users` table also has a unique `email`, and the `parcels` table also has a unique `tracking_id`.
 
**Therefore, our schema follows 1NF because the columns store individual values instead of lists or repeating groups.**
 
## 3. Second Normal Form (2NF)
 
A table is in Second Normal Form when:
 
- It is already in 1NF.
- Every non-key column depends on the whole candidate key, not just a part of a composite key.
This is mainly important for tables that have a composite primary key.
 
### How it applies to our database
 
Neither of our tables has a composite primary key:
 
| Table | Primary key |
|---|---|
| `users` | `id` |
| `parcels` | `id` |
 
Both tables use a single-column primary key, so there cannot be a partial dependency on a part of a composite primary key.
 
For example, in the `parcels` table, `courier_name`, `arrival_date`, and `status` all describe one particular parcel, which is identified by `id`:
 
`id -> tracking_id, student_name, courier_name, arrival_date, status, ...`
 
**Therefore, the non-key columns in our tables depend on the complete key, which means the schema follows 2NF.**
 
## 4. Third Normal Form (3NF)
 
A table is in Third Normal Form when:
 
- It is already in 2NF.
- Non-key columns do not depend on other non-key columns (there should not be a transitive dependency).
In simple terms, non-key columns should describe the key of that table, rather than another non-key column.
 
### How it applies to our database
 
In our `users` table, `id` identifies a user and determines the other user details, such as `name`, `email`, `registration_number`, and `role`.
 
The functional dependency is:
 
`id -> name, email, password, registration_number, role, created_at, updated_at`
 
We have also kept information about different entities in separate tables. For example:
 
- Account details (name, email, role) are stored in `users`.
- Parcel details (tracking ID, courier, arrival date, status) are stored in `parcels`.
For example, the `parcels` table stores `registered_by_id` and `collected_by_id` as foreign keys. It does not repeat the staff member's name, email, or role for every parcel. We can get those details by joining `parcels` with `users`, which is what the queries in `dbms/04_queries.sql` do.
 
This avoids storing the same staff information repeatedly.
 
There is one point that needs a careful look. The `parcels` table stores `student_name`, `student_registration_number`, and `student_email`. If a student's registration number always decided the student's name and email, then `student_name` and `student_email` would depend on `student_registration_number`, which is a non-key column, and this would be a transitive dependency. This is explained in Section 6. In our design, these three columns are treated as details of the parcel itself: the contact details that the staff member entered when the parcel was registered. They are not copied automatically from the `users` table, they can be corrected for a single parcel, and the database does not force the same registration number to always have the same name or email. So the dependency is not part of the functional dependencies of our schema.
 
**Therefore, our schema follows 3NF because the tables are separated by entity and non-key attributes depend on their table's key, rather than on other non-key attributes. The student columns in `parcels` are a deliberate design choice and are discussed in Section 6.**
 
## 5. Boyce-Codd Normal Form (BCNF)
 
BCNF is a stricter version of 3NF.
 
A table is in BCNF if, for every non-trivial functional dependency:
 
`X -> Y`
 
`X` must be a superkey. In other words, the left side of every such dependency must be able to identify a complete row.
 
### How it applies to our database
 
In our schema, the main functional dependencies are based on the primary keys and unique constraints.
 
Some examples are:
 
- In `users`, `id` identifies a user. `email` is `NOT NULL UNIQUE`, so it can also identify a user.
- In `parcels`, `id` identifies a parcel. `tracking_id` is `NOT NULL UNIQUE`, so it can also identify a parcel.
For these dependencies, the determinant is a candidate key or a superkey. So, based on the functional dependencies represented by our current schema, the tables appear to satisfy BCNF as well.
 
One small detail is that `registration_number` in `users` is not unique in the database. Staff accounts have no registration number, and the app (not the database) checks that two students do not share one. Because of this, I have not treated it as a candidate key. The same applies to `student_registration_number` in `parcels`, which is expected to repeat, because one student can receive many parcels.
 
## 6. Denormalized Attributes
 
There are a few columns in our schema that store information which could also be found somewhere else:
 
| Table | Column | What it stores |
|---|---|---|
| `parcels` | `student_name` | Name of the student, as entered when the parcel was registered |
| `parcels` | `student_email` | Email of the student, as entered when the parcel was registered |
| `parcels` | `student_registration_number` | Registration number of the student the parcel is for |
| `parcels` | `status` | Whether the parcel is `PENDING` or `COLLECTED` |
 
**Student details in `parcels`.** These could be stored in a separate `students` table, and `parcels` could then point to it with a foreign key. We have not done this for the following reasons:
 
- A parcel can arrive for a student who does not have a UniCrate login yet, so there is not always a row in `users` to point to.
- Staff register a parcel using only what is written on it, and they can correct the details of one parcel without changing any other parcel.
- The privacy rule of the app works by comparing the registration number of the logged-in student with the registration number on the parcel. A student sees a parcel only if the two numbers match, so the number has to be stored on the parcel.
- This matches the `Parcel` model in the main UniCrate repo, which the AP repo must follow.
The cost is that the same student's name or email can be stored in many parcels, and a spelling mistake in one parcel will not be fixed in the others automatically.
 
**`status` and `collected_at`.** A parcel is collected exactly when `collected_at` has a value, so `status` can be worked out from `collected_at`. We have kept `status` as its own column because it makes the queries simpler and because it has its own index (`idx_parcels_status`), which is used to filter parcels and to count pending and collected parcels on the dashboard. The `chk_parcels_collection` constraint makes sure the two never disagree: a `COLLECTED` parcel must have `collected_at` and `collected_by_id`, and a `PENDING` parcel must have neither.
 
These values are set by the application only when a parcel is registered or collected, so there is nothing that has to be kept in sync again and again.
 
## 7. Conclusion
 
After looking at the tables and their keys, our UniCrate database follows the normal forms as follows:
 
- **1NF:** Values are atomic, and the parcels of a user are stored in their own table instead of a list.
- **2NF:** Non-key columns depend on the complete primary key. Both tables have a single-column primary key, so there are no partial dependencies.
- **3NF:** Information about accounts and parcels is stored in separate tables, and staff details are not repeated in `parcels`. The student columns in `parcels` are kept on purpose, as explained in Section 6.
- **BCNF:** Based on the functional dependencies represented in the current schema, every determinant is a candidate key or a superkey.
Overall, normalization helps keep our database organized and reduces unnecessary duplication. We have also kept the student details and the `status` column as denormalized values, because parcels must be recorded even for students without an account, and because it keeps the common queries simple and fast.
 