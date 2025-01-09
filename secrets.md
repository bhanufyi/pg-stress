```bash 

printf "s3cr3t" | gcloud secrets create dev-db-password --data-file=- --location=us-east1
```