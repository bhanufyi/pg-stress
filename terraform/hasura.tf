

resource "google_cloud_run_service" "hasura" {
  name     = "hasura-crm-stage-branch"
  location = "us-east1"
  template {
    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"      = 1
        "autoscaling.knative.dev/maxScale"      = 1
        "run.googleapis.com/cloudsql-instances" = local.cloud_sql_instance
      }
    }
    spec {
      service_account_name = "ai-ml-discover@bhanufyi.iam.gserviceaccount.com"
      timeout_seconds      = 3000
      containers {
        image = "hasura/graphql-engine:v2.33.4"
        ports {
          container_port = "3000"
        }
        resources {
          limits = {
            cpu    = 2
            memory = "4Gi"
          }
          requests = {
            cpu    = 2
            memory = "4Gi"
          }
        }
        env {
          name  = "GCP_PROJECT"
          value = "bhanufyi"
        }
        env {
          name  = "PGAPPNAME"
          value = "hasura-crm-stage-branch"
        }
        env {
          name  = "HASURA_GRAPHQL_DATABASE_URL"
          value = "postgres://bhanu:${data.google_secret_manager_secret_version.dev_db_password.secret_data}@/${local.database}?host=/cloudsql/${local.cloud_sql_instance}"
        }
        env {
          name  = "HASURA_GRAPHQL_SERVER_PORT"
          value = "3000"
        }
        env {
          name  = "HASURA_GRAPHQL_ENABLE_REMOTE_SCHEMA_PERMISSIONS"
          value = "true"
        }
        env {
          name  = "HASURA_GRAPHQL_EXPERIMENTAL_FEATURES"
          value = "optimize_permission_filters"
        }

        env {
          name  = "HASURA_GRAPHQL_UNAUTHORIZED_ROLE"
          value = "anonymous"
        }

        # Logs everything on test
        env {
          name  = "HASURA_GRAPHQL_ENABLED_LOG_TYPES"
          value = "startup, http-log, webhook-log, websocket-log, query-log"
        }

        # Set dev mode for GraphQL requests; include the internal key in the errors extensions of the response (if required).
        # To have extended errors on stage/test
        env {
          name  = "HASURA_GRAPHQL_DEV_MODE"
          value = "true"
        }

        env {
            name = "HASURA_GRAPHQL_ADMIN_SECRET"
            value = "notsosecret"
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_policy" "hasura-noauth" {
  location    = google_cloud_run_service.hasura.location
  service     = google_cloud_run_service.hasura.name
  policy_data = data.google_iam_policy.noauth.policy_data
}