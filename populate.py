#!/usr/bin/env python3
import psycopg2
import numpy as np
from nanoid import generate

# Connection parameters
conn = psycopg2.connect(
    host="localhost", port=5432, database="mydb", user="postgres", password="postgres"
)
cur = conn.cursor()

user_count = 10_000
alphabet = "0123456789"

# Zipf parameter; values closer to 1 produce a heavier skew towards 1.
zipf_param = 1.2


# Helper function to get a count from zipf distribution between 1 and 5
def zipf_limited(max_val=5):
    # Draw until we get a value <= max_val
    # With zipf(1.2), values are heavily skewed towards 1, so this should be fast
    val = np.random.zipf(zipf_param)
    while val > max_val:
        val = np.random.zipf(zipf_param)
    return val


batch_size = 10000
count = 0

for i in range(1, user_count + 1):
    # Generate a random user name
    user_name = f"User {i}"

    # Insert user and get UUID
    cur.execute("INSERT INTO users (name) VALUES (%s) RETURNING id;", (user_name,))
    user_id = cur.fetchone()[0]

    # Determine how many emails and phone numbers for this user
    num_emails = zipf_limited(5)
    num_phones = zipf_limited(5)

    # Insert emails
    for e in range(num_emails):
        email = f"user{user_id}_{e}@example.com"
        cur.execute(
            "INSERT INTO emails (user_id, email) VALUES (%s, %s) RETURNING id;",
            (user_id, email),
        )
        email_id = cur.fetchone()[0]  # Get the email UUID (optional, not used further)

    # Insert phone numbers
    for p in range(num_phones):
        phone_number = generate(alphabet, 16)  # 16-digit unique number
        cur.execute(
            "INSERT INTO phone_numbers (user_id, phone_number) VALUES (%s, %s) RETURNING id;",
            (user_id, phone_number),
        )
        phone_id = cur.fetchone()[0]  # Get the phone UUID (optional, not used further)

    count += 1
    if count % batch_size == 0:
        conn.commit()
        print(f"Inserted {count} users...")

# Final commit
conn.commit()

cur.close()
conn.close()
