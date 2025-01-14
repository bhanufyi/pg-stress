# How I Automated PostgreSQL Backups and Dynamic Databases with GitHub Actions and Terraform

Ever been stuck in a database backup loop, manually running `pg_restore` like it's the '90s? Well, I was—until I decided to automate the chaos. Here's how I transformed our PostgreSQL production backups into dynamic, on-demand databases for every feature branch. Spoiler: GitHub Actions, Terraform, and a lot of Docker magic were involved.

## The Problem: One DB to Rule Them All (and Break Everything)

Our dev environment was a warzone. Everyone shared the same database, and testing new features felt like playing Jenga—one wrong move, and everything crashed. We needed isolated databases for each preview branch to avoid stepping on each other's toes.

## The Idea: Automate All the Things

1. **Backup the Prod DB Regularly**
2. **Refresh a Template DB from the Latest Backup**
3. **Spin Up New Databases for Preview Branches on Demand**

Simple, right? Well, let's break it down.

## Step 1: Local Playground with Docker Compose

Before touching prod, I spun up a PostgreSQL instance locally with Docker Compose and loaded it with 10k fake users, emails, and phone numbers. Just a basic relational setup—good enough to break things safely.

## Step 2: Backups—`pg_dump` to the Rescue

Next came the backup strategy. I debated between SQL (`pg_dump` default) and custom `.dump` formats. I chose `.dump` for its compressed nature (or so I believe—because why else does it even exist?).

## Step 3: Terraforming Cloud SQL on GCP

Time to go cloud-native. I wrote Terraform scripts to:

- Spin up **prod** and **dev** Cloud SQL instances.
- Create DB users with passwords stored in Secret Manager (yes, Terraform can do that too!).

I even made GitHub Actions to run `terraform apply` and `terraform destroy` (bit overkill, but hey—learning > perfection).

## Step 4: Cloud SQL Proxy & The Great `pg_restore`

Using `cloud_sql_proxy`, I connected to the prod instance and restored the backup:

```
pg_restore -h 127.0.0.1 -p 5432 -U bhanu -d prod_db prod_backup.dump
```

## Step 5: Automating Backups with GitHub Actions

The `backup_prod.yaml` workflow:

- Connects to the prod instance.
- Takes a `pg_dump`, encrypts it, compresses it, and uploads it to GCP.

## Step 6: Refreshing the Template DB

The `prod_template.yaml` workflow:

- Pulls the latest backup from GCS.
- Drops and recreates the **prod-template** DB in the dev instance.

```
act workflow_dispatch --container-architecture=linux/amd64 \
    -W .github/workflows/prod_template.yaml \
    -s GCP_SERVICE_ACCOUNT_KEY="$(cat local-dev.json)" \
    -s GCP_PROJECT_ID="bhanufyi" \
    -s DB_PASSWORD=dev-password-here \
    -s GPG_PASSPHRASE=secret-passphrase-here
```

## Step 7: Preview Branch Magic

In `main.yaml`, a GitHub Action checks for branches prefixed with `stage_` and spins up a new DB from the **prod-template**:

```
act push --container-architecture=linux/amd64 \
    -W .github/workflows/main.yaml \
    -s GCP_SERVICE_ACCOUNT_KEY="$(cat local-dev.json)" \
    -s GCP_PROJECT_ID="bhanufyi" \
    -s DB_PASSWORD=dev-password-here \
    --eventpath <(echo '{"ref": "refs/heads/stage_feature_branch"}')
```

## Step 8: Next Steps

- Deploy services to Cloud Run using Terraform.
- Implement sanity checks and Docker image builds.
- Automate cleanup of databases and cloud resources.

## Pro Tip: Use `act` for Local Action Testing

Debugging GitHub Actions by pushing commits is a nightmare. Enter [`act`](https://github.com/nektos/act)—a game-changer for local workflow testing.

## Final Thoughts

What started as a simple backup solution turned into a full-blown CI/CD pipeline for PostgreSQL. Next up: smarter data sampling and full automation. Until then, happy coding!

---

*Let’s connect on [**LinkedIn**](https://www.linkedin.com/in/bhanufyi) or check out my projects on [**GitHub**](https://github.com/bhanufyi)!*