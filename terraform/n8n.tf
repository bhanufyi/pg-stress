resource "google_cloud_run_service" "n8n" {
  name     = "n8n"
  location = "us-east1"
  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = 1
        "autoscaling.knative.dev/maxScale"      = 1
        "run.googleapis.com/cloudsql-instances" = local.cloud_sql_instance
        "run.googleapis.com/cpu-throttling"     = false
      }
    }
    spec {
      service_account_name = "ai-ml-discover@${local.project}.iam.gserviceaccount.com"
      containers {
        image = "n8nio/n8n:1.77.0"
        resources {
          limits = {
            cpu    = 4
            memory = "8Gi"
          }
          requests = {
            cpu    = 4
            memory = "8Gi"
          }
        }

        # prune execution data every 7 days
        # https://docs.n8n.io/getting-started/installation/advanced/maintenance.html
        env {
          name  = "EXECUTIONS_DATA_PRUNE"
          value = "true"
        }
        env {
          name  = "EXECUTIONS_DATA_MAX_AGE"
          value = "168"
        }

        env {
          name  = "GOOGLE_PROJECT"
          value = local.project
        }
        env {
          name  = "REGION"
          value = local.region
        }

        # n8n db credentials
        env {
          name  = "DB_TYPE"
          value = "postgresdb"
        }
        env {
          name  = "DB_POSTGRESDB_HOST"
          value = "/cloudsql/${local.cloud_sql_instance}"
        }
        env {
          name  = "DB_POSTGRESDB_DATABASE"
          value = local.database
        }
        env {
          name  = "DB_POSTGRESDB_SCHEMA"
          value = "n8n"
        }
        env {
          name  = "DB_POSTGRESDB_USER"
          value = "bhanu"
        }
        env {
          name  = "DB_POSTGRESDB_PASSWORD"
          value = data.google_secret_manager_secret_version.dev_db_password.secret_data
        }
        # other n8n configuration
        env {
          name  = "N8N_ENCRYPTION_KEY"
          value = "WgdGKn9UUSywQZa6"
        }
        env {
          name  = "N8N_BASIC_AUTH_ACTIVE"
          value = "true"
        }
        env {
          name  = "N8N_BASIC_AUTH_USER"
          value = "bhanu"
        }
        env {
          name  = "N8N_BASIC_AUTH_PASSWORD"
          value = "notsosecret"
        }
        env {
          name  = "N8N_PROTOCOL"
          value = "https"
        }
        env {
          name  = "EXECUTIONS_PROCESS"
          value = "main"
        }
        env {
          name  = "GENERIC_TIMEZONE"
          value = "Etc/GMT"
        }
        env {
          name  = "TZ"
          value = "Etc/GMT"
        }

        env {
          // to prevent deregister webhooks on cloudrun scale/restarts
          name  = "N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN"
          value = "true"
        }
        env {
          name  = "NODE_FUNCTION_ALLOW_BUILTIN"
          value = "crypto"
        }

        ports {
          container_port = 5678
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_policy" "n8n-noauth" {
  location    = google_cloud_run_service.n8n.location
  service     = google_cloud_run_service.n8n.name
  project     = local.project
  policy_data = data.google_iam_policy.noauth.policy_data
}