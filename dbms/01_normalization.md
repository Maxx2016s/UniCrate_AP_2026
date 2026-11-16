# Normalization 

## 1. What is Normalization?

Normalization is a way of organizing data in a database so that we do not store the same information unnecessarily in many places. It helps reduce data duplication and avoids problems when inserting, updating, or deleting records.

For our Instagram database, we have separate tables for users, posts, follows, hashtags, media, likes, comments, and stories. In this document, I have explained how the schema follows the normal forms we have studied: 1NF, 2NF, 3NF, and BCNF.

## 2. First Normal Form (1NF)

A table is in First Normal Form when:

- Each column contains a single, atomic value.
- There are no lists or multiple values stored in one cell.
- Each row can be uniquely identified.

### How it applies to our database

For example, one Instagram post can have multiple media files and multiple hashtags. If we stored all the media URLs or hashtags in one column separated by commas, that column would contain multiple values and would not follow 1NF.

An example of a table that is not in 1NF:

| post_id | user_id | media_urls | hashtags |
|---|---|---|---|
| 101 | 1 | image1.jpg, image2.jpg | travel, photography |

To avoid this, we have created separate tables:

- `posts` stores the main details of each post.
- `post_media` stores the media files belonging to posts.
- `hashtags` stores each hashtag separately.
- `post_hashtags` connects posts with their hashtags.

For example, `post_media` stores one media item per row. The combination of `post_id` and `position` identifies each media item in a post.

**Therefore, our schema follows 1NF because the columns store individual values instead of lists or repeating groups.**

## 3. Second Normal Form (2NF)

A table is in Second Normal Form when:

- It is already in 1NF.
- Every non-key column depends on the whole candidate key, not just a part of a composite key.

This is mainly important for tables that have a composite primary key.

### How it applies to our database

Some tables in our schema have composite primary keys:

| Table | Primary key |
|---|---|
| `follows` | `(follower_id, followee_id)` |
| `post_hashtags` | `(post_id, hashtag_id)` |
| `post_media` | `(post_id, position)` |
| `likes` | `(user_id, post_id)` |

For example, in the `likes` table, the `created_at` value depends on both the user and the post. A user can like many posts, and a post can be liked by many users. So neither `user_id` nor `post_id` alone is enough to identify a particular like.

The functional dependency is:

`(user_id, post_id) -> created_at`

Similarly, in the `follows` table, `status` and `created_at` depend on the combination of `follower_id` and `followee_id`.

In `post_media`, details such as `media_url`, `media_type`, `width`, and `height` depend on both `post_id` and `position`.

The other tables use a single-column primary key, so there cannot be a partial dependency on a part of a composite primary key.

**Therefore, the non-key columns in our tables depend on the complete key, which means the schema follows 2NF.**

## 4. Third Normal Form (3NF)

A table is in Third Normal Form when:

- It is already in 2NF.
- Non-key columns do not depend on other non-key columns (there should not be a transitive dependency).

In simple terms, non-key columns should describe the key of that table, rather than another non-key column.

### How it applies to our database

In our `users` table, `user_id` identifies a user and determines the other user details, such as `username`, `full_name`, `email`, `bio`, and `account_type`.

The functional dependency is:

`user_id -> username, full_name, email, bio, account_type, ...`

We have also kept information about different entities in separate tables. For example:

- User details are stored in `users`.
- Post details are stored in `posts`.
- Hashtag details are stored in `hashtags`.
- Media details are stored in `post_media`.
- Comment details are stored in `comments`.
- Story information is stored in `stories`.

For example, the `posts` table stores `user_id` as a foreign key. It does not repeat the user's username, email, and other profile details for every post. We can get those details by joining `posts` with `users`.

This avoids storing the same user information repeatedly.

**Therefore, our schema follows 3NF because the tables are separated by entity and non-key attributes depend on their table's key, rather than on other non-key attributes.**

## 5. Boyce-Codd Normal Form (BCNF)

BCNF is a stricter version of 3NF.

A table is in BCNF if, for every non-trivial functional dependency:

`X -> Y`

`X` must be a superkey. In other words, the left side of every such dependency must be able to identify a complete row.

### How it applies to our database

In our schema, the main functional dependencies are based on the primary keys and unique constraints.

Some examples are:

- In `users`, `user_id` identifies a user. `username` is also unique, so it can identify a user.
- In `posts`, `post_id` identifies a post.
- In `hashtags`, `hashtag_id` identifies a hashtag, and `tag` is unique.
- In `likes`, the combination `(user_id, post_id)` identifies a like.
- In `follows`, `(follower_id, followee_id)` identifies a follow relationship.
- In `post_hashtags`, `(post_id, hashtag_id)` identifies a post-hashtag relationship.
- In `post_media`, `(post_id, position)` identifies a media item within a post.

For these dependencies, the determinant is a candidate key or a superkey. So, based on the functional dependencies represented by our current schema, the tables appear to satisfy BCNF as well.

One small detail is that `email` is declared `UNIQUE`, but it is not declared `NOT NULL`. Because of this, I have not treated it as a candidate key for every possible row.

## 6. Denormalized Attributes

There are a few columns in our schema that store counts:

| Table | Column | What it stores |
|---|---|---|
| `users` | `followers_count` | Number of followers |
| `users` | `following_count` | Number of accounts followed |
| `posts` | `like_count` | Number of likes |
| `posts` | `comment_count` | Number of comments |
| `stories` | `view_count` | Number of views |

These counts could also be calculated from the related tables using SQL queries. For example, the number of likes on a post can be calculated by counting rows in the `likes` table for that post.

We have kept these count columns because they can make it faster to display counts without running aggregate queries every time. This is an example of denormalization done for performance.

However, the application will need to update these values whenever a like, comment, follow, or story view is added or removed. Otherwise, the stored counts could become different from the actual records.

## 7. Conclusion

After looking at the tables and their keys, our Instagram database follows the normal forms as follows:

- **1NF:** Values are atomic, and repeating or multivalued data is stored in separate tables.
- **2NF:** Non-key columns depend on the complete primary key, including in tables with composite keys.
- **3NF:** Information about different entities is stored in separate tables, avoiding unnecessary transitive dependencies.
- **BCNF:** Based on the functional dependencies represented in the current schema, every determinant is a candidate key or superkey.

Overall, normalization helps keep our database organized and reduces unnecessary duplication. We have also kept a few count columns as denormalized values to make common read operations faster, while the actual likes, comments, follows, and views are represented through their related records.
