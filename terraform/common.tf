data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

data "google_iam_policy" "functionsnoauth" {
    binding {
        role = "roles/cloudfunctions.invoker"
        members = [
            "allUsers"
        ]
    }
}

locals {
      cloud_sql_instance         = "bhanufyi:us-east1:bhanufyi-dev-db"
      database = "stage-feature-branch"
      project = "bhanufyi"
      region = "us-east1"

}

data "google_secret_manager_secret_version" "dev_db_password" {
  secret = "dev-db-password"

  depends_on = [ resource.google_secret_manager_secret_version.secrets_versions ]
}
