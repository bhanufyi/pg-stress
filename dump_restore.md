# PostgreSQL Backups and Restores on GCP: The Manual Way Before CI/CD Took Over

Before automating PostgreSQL backups with GitHub Actions and Terraform, I took the old-school route. This blog walks through my hands-on journey with Docker, `pg_dump`, and GCP—before the automation magic happened.

## Step 1: Spinning Up PostgreSQL with Docker

To start, I spun up a PostgreSQL database locally using Docker Compose. I populated it with 10,000 users, each with random emails and phone numbers.

**Backup the Database in Custom Format:**

```bash
docker exec -it pg-stress-db-1 pg_dump -U postgres -F c -f /backup/full_backup.dump mydb

```

**Backup the Database in SQL Format:**

```bash
docker exec -it pg-stress-db-1 pg_dump -U postgres mydb > ./backups/full_backup.sql

```

## Step 2: Restoring the Database Locally

Created a fresh database and restored the backup:

```bash
docker exec -it pg-stress-db-1 psql -U postgres -c "CREATE DATABASE testdb;"

```

```bash
docker exec -it pg-stress-db-1 pg_restore -U postgres -d testdb /backup/full_backup.dump

```

## Step 3: Setting Up Cloud SQL on GCP

With the local setup working, it was time to move to the cloud. First, I created a Cloud SQL instance on GCP:

```bash
gcloud sql instances create bhanufyi-db-dev --database-version=POSTGRES_15 --tier=db-f1-micro --region=us-east1 --storage-size=10GB

```

Then, I connected to it using Cloud SQL Proxy:

```bash
cloud_sql_proxy -instances=bhanufyi:us-east1:bhanufyi-db-dev=tcp:5432

```

Created a new database in the instance:

```bash
gcloud sql databases create mydb --instance=bhanufyi-db-dev

```

## Step 4: Attempted Cloud Import (Spoiler: It Failed)

Naturally, I tried importing the `.dump` file directly. Spoiler: GCP only supports SQL imports, not custom dumps.

```bash
gcloud sql import sql bhanufyi-db-dev gs://bhanufyi-pg-backups/full_backup.dump \
    --database=mydb

```

**Result:** Nope. Manual restore it is!

## Step 5: Granting Permissions to GCS

To proceed, I had to give Cloud SQL permission to access the backup in Google Cloud Storage:

```bash
gsutil iam ch \
  serviceAccount:p922801875648-aoagom@gcp-sa-cloud-sql.iam.gserviceaccount.com:roles/storage.admin \
  gs://bhanufyi-pg-backups

```

## Step 6: Manual Restore to Cloud SQL

Connected to the Cloud SQL instance and restored the database manually:

```bash
pg_restore \
    --host=127.0.0.1 \
    --port=5432 \
    --username=postgres \
    --dbname=mydb \
    --format=custom \
    --clean \
    --if-exists \
    ./backup/full_backup.dump

```

Or to poke around the DB:

```bash
psql --host=127.0.0.1 \
     --port=5432 \
     --username=postgres \
     --dbname=mydb

```

## Step 7: Cleaning Up

Once I was done experimenting, I deleted the dev Cloud SQL instance:

```bash
gcloud sql instances delete bhanufyi-db-dev

```

## Final Thoughts

Before automation, this was my hands-on trial-and-error process for backing up and restoring PostgreSQL databases on GCP. It wasn’t pretty, but it laid the foundation for the fully automated pipeline I built later with GitHub Actions and Terraform.

Sometimes, the manual path is the best way to learn—even if it involves a few failed imports along the way.

---

*Let’s connect on [**LinkedIn**](https://www.linkedin.com/in/bhanufyi) or check out my projects on [**GitHub**](https://github.com/bhanufyi)!*