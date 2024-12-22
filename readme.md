# PostgreSQL Data Simulation and Analysis

This project demonstrates a high-performance setup for generating and managing large-scale simulated datasets in PostgreSQL. Using Docker for easy database provisioning and Python for data generation, the project creates:

- **10 million users**, each uniquely identified by a UUID.
- Each user is assigned **emails and phone numbers** based on a Zipf distribution, ensuring a realistic variation where most users have 1-3 emails and phone numbers, but some have up to 5.

## Key Highlights

1. **Database Scale**:
    - The dataset spans **50 million rows** across three tables: `users`, `emails`, and `phone_numbers`.
2. **Efficient Storage**:
    - The total database size is approximately **9.27 GB**, demonstrating efficient handling of a large volume of data.
3. **UUIDs for Global Uniqueness**:
    - All primary keys use UUIDs (`uuid_generate_v4()`), ensuring globally unique identifiers across tables.
4. **Realistic Data Distribution**:
    - Emails and phone numbers are distributed based on a Zipf distribution, simulating real-world scenarios where most users have fewer associated records, and a few have more.
5. **Analysis-Ready**:
    - SQL queries are provided for analyzing row counts, database size, and distribution of records, offering a comprehensive view of the dataset.

This project is ideal for understanding the challenges and optimizations required for handling large datasets in PostgreSQL and serves as a foundation for further exploration in data-intensive applications.

---

##

---

## Setup Instructions

### 1. Start the PostgreSQL Database

Run the following command to start the PostgreSQL database using Docker:

```bash
docker compose up -d
```

---

### 2. Set Up the Python Environment

1. Create a virtual environment:

    ```bash
    python3.10 -m venv .venv
    source .venv/bin/activate
    ```

2. Install the required dependencies:

    ```bash
    pip install -r requirements.txt
    
    ```

---

### 3. Populate the Database

Run the Python script to generate and insert data into the database:

```bash
python populate.py

```

The script uses a combination of UUIDs and Zipf distribution to simulate a realistic dataset.

---

## SQL Queries for Analysis

### 1. Total Rows Across All Tables

This query retrieves the row count for each table and calculates the total number of rows across all tables:

```sql
SELECT
    table_name,
    table_rows AS row_count
FROM (
    SELECT
        relname AS table_name,
        n_live_tup AS table_rows
    FROM
        pg_stat_user_tables
) subquery
UNION ALL
SELECT
    'Total Rows' AS table_name,
    SUM(table_rows) AS row_count
FROM (
    SELECT
        n_live_tup AS table_rows
    FROM
        pg_stat_user_tables
) subquery;

```

**Output**:

![images/total_rows.png](images/total_rows.png)

---

### 2. Size of the Current Database

To get the size of the current database in a human-readable format:

```sql
sql
Copy code
SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;

```

**Output**:

![Size of generated DB](images/size_of_db.png)

---

### 3. Sizes of All Databases

To get the sizes of all databases on the PostgreSQL instance:

```sql
sql
Copy code
SELECT
    datname AS database_name,
    pg_size_pretty(pg_database_size(datname)) AS database_size
FROM
    pg_database
ORDER BY
    pg_database_size(datname) DESC;

```

**Output**:

![images/size_of_all_dbs.png](images/size_of_all_dbs.png)

---

### 4. Distribution of Emails per User

This query groups users by the number of emails they have and counts how many users fall into each group:

```sql
sql
Copy code
SELECT
    email_count,
    COUNT(*) AS user_count
FROM (
    SELECT user_id, COUNT(*) AS email_count
    FROM emails
    GROUP BY user_id
) subquery
GROUP BY email_count
ORDER BY email_count;

```

**Output**:

![images/email_distribution.png](images/email_distribution.png)

---

## Key Features of the Project

1. **UUID Usage**:
    - All primary keys (`users.id`, `emails.id`, `phone_numbers.id`) use UUIDs (`uuid_generate_v4()`), ensuring globally unique identifiers.
2. **Realistic Data Simulation**:
    - User emails and phone numbers are generated using Python and a Zipf distribution for a realistic distribution of data..
3. **Comprehensive Analysis**:
    - SQL queries provide insights into the structure and size of the database, as well as user behavior patterns (e.g., email distribution).

### Future Plans for Improving Data Generation Performance

To significantly reduce the time taken for database population, consider the following strategies:

1. **Batch Inserts**:
    - Insert multiple rows in a single query (e.g., 1000 users, emails, or phone numbers per query).
    - This reduces the overhead of individual insert operations.
2. **Parallel Processing**:
    - Use Python's `concurrent.futures` or `multiprocessing` module to parallelize data generation and inserts.
    - Divide the data into chunks and assign each chunk to a separate process or thread.
3. **Copy Command for Bulk Inserts**:
    - Generate data in CSV files and use PostgreSQL's `COPY` command for bulk importing.
    - This is faster than executing `INSERT` queries for large datasets.
4. **Temporary Table Usage**:
    - Insert data into a temporary table without constraints or indexes, then transfer it to the main tables.
    - Constraints and indexes can be re-enabled after the bulk insert.
5. **Database Index Management**:
    - Disable indexes and constraints during data insertion and re-enable them afterward to speed up writes.
6. **Connection Pooling**:
    - Use a connection pooler like `pgbouncer` to optimize database connections and reduce connection overhead.
7. **Use of Parallel Transactions**:
    - Open multiple connections to the database and distribute insert operations among them.
8. **Optimized UUID Generation**:
    - Generate UUIDs in Python using libraries like `uuid` or `nanoid` to avoid relying on PostgreSQL's `uuid_generate_v4()` during inserts.
9. **Avoid Autocommit**:
    - Use transaction batching (e.g., commit every 10,000 inserts) to reduce transaction overhead.
10. **Pre-generate Related Data**:
    - Generate users, emails, and phone numbers independently, then load them in parallel without waiting for sequential dependencies.
