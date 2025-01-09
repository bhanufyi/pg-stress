# DB CI/CD for PR branches
Ok I have done a lot of stuff here, let's try to understand this 

1st I have created a db locally by running docker-compose file
explaination for running docker compose and generating dump is mentioned in readme.md 
just make to sure to generate the dump file somehow, for convenience I'm adding my dump file to version control
it's db for 10_000 users and phone numbers and emails for each user total db size is around 1.8MB which is good enough for testing 

now let's create 2 postgres instances, I have created a terraform folder which has main.tf, I crammed all the infra setup that file 
i.e secrets for db passwords for instances, instance creation, and db user creation
I have `infra_provision.yaml` which is a github actions that creates terraform workspace and runs terraform apply on it
but turns out destroy of these instances is not that easy, I had drop the dbs first to destroy the instances so not much of use for this action, instead you can just go this folder run `terraform init` and `terraform apply` to create the instances
and `terraform destroy` after dropping all dbs to destroy the resources

ok once instances are created, run cloud_sql_proxy locally and connect to prod instance, create a db named prod_db and restore the dump file to it

we have `backup_prod.yaml` which connects to prod instance and takes a backup of prod_db, encrypts, compresses and uploads to gcp bucket


`prod_template.yaml` action connects to dev instance, picks up the latest backup from gcp bucket, downloads, decrypts, decompresses and restores the backup to db called prod-template, we drop this db if it already exists that way we have latest template db

they we go, now we have a template db, which we could use to spin up dbs for each branch pr

in the `main.yaml` I create a db for branch, if the branch starts with `stage_` creating db using template would significantly reduce the time to create db, instead of restoring from dump file.

All the testing is done locally using act, instead of pushing to github and waiting for the actions to run, I can run the actions locally and see the results

for prod_template.yaml 
```bash
act workflow_dispatch --container-architecture=linux/amd64 \
    -W .github/workflows/prod_template.yaml \
    -s GCP_SERVICE_ACCOUNT_KEY="$(cat local-dev.json)" \
    -s GCP_PROJECT_ID="bhanufyi" \
-s DB_PASSWORD=dev-password-here \
-s GPG_PASSPHRASE=secret-passphrase-here
```

for main.yaml 
```bash
act push --container-architecture=linux/amd64 \
    -W .github/workflows/main.yaml \
    -s GCP_SERVICE_ACCOUNT_KEY="$(cat local-dev.json)" \
    -s GCP_PROJECT_ID="bhanufyi" \
    -s DB_PASSWORD=dev-password-here \
    --eventpath <(echo '{"ref": "refs/heads/stage_feature_branch"}')
```

here local-dev.json that has necessary permissions to access cloudsql, storage, secretmanager etc

Next Steps:

create cloud run app that uses this db, so that we can demonstrate app using the created and also cleanup of created db, and app resources using terraform