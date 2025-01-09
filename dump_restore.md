```bash
docker exec -it pg-stress-db-1 pg_dump -U postgres -F c -f /backup/full_backup.dump mydb
```
```bash
docker exec -it pg-stress-db-1 pg_dump -U postgres mydb > ./backups/full_backup.sql
```

```bash
 docker exec -it pg-stress-db-1 psql -U postgres -c "CREATE DATABASE testdb;"
 ```

```bash
docker exec -it pg-stress-db-1 pg_restore -U postgres -d testdb /backup/full_backup.dump

```

```bash
gcloud sql instances create bhanufyi-db-dev --database-version=POSTGRES_15 --tier=db-f1-mirco --region=us-east1 --storage-size=10GB
```
```
cloud_sql_proxy -instances=bhanufyi:us-east1:bhanufyi-db-dev=tcp:5432
```

```bash
gcloud sql databases create mydb --instance=bhanufyi-db-dev
```

```bash
gcloud sql import sql bhanufyi-db-dev gs://bhanufyi-pg-backups/full_backup.dump \
    --database=mydb
```
didn't work, had to do manual restore as it only supports direct format

```bash
gsutil iam ch \
  serviceAccount:p922801875648-aoagom@gcp-sa-cloud-sql.iam.gserviceaccount.com:roles/storage.admin \
  gs://bhanufyi-pg-backups
```

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

```bash
psql --host=127.0.0.1 \                     ✔  pg-stress   base   13:01:38  
     --port=5432 \
     --username=postgres \
     --dbname=mydb
```

```bash
gcloud sql instances delete bhanufyi-db-dev
```
