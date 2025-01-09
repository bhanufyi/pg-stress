terraform {
  required_version = ">= 1.10.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.14.1"
    }
  }

  backend "gcs" {
    bucket  = "bhanufyi-terraform-backend" # Replace with your bucket name
    prefix  = "terraform/pg-stress"        # Folder structure in the bucket
  }
}

variable "secrets" {
  description = "Map of secrets to be created."
  type        = map(string)
  # default = {
  #   dev-db-password = "value_one"
  #   prod-db-password = "value_two"
  # }
}

provider "google" {
  project = "bhanufyi"
  region  = "us-east1"
  # credentials = file("service-account-key.json") 
  # (Uncomment and provide path if not using application default creds)
}



resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  secret_id = each.key

  labels = {
    label = "pg-stress"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secrets_versions" {
  for_each = var.secrets

  secret = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value
  depends_on = [ google_secret_manager_secret.secrets ]
}


data "google_secret_manager_secret_version_access" "dev_db_password" {
  secret = "dev-db-password"
  depends_on = [ google_secret_manager_secret_version.secrets_versions ]
}

data "google_secret_manager_secret_version_access" "prod_db_password" {
  secret = "prod-db-password"
  depends_on = [ google_secret_manager_secret_version.secrets_versions ]
}

resource "google_sql_database_instance" "dev-db" {
  name                 = "bhanufyi-dev-db"
  project              = "bhanufyi"
  region               = "us-east1"
  database_version     = "POSTGRES_15"

  settings {
    tier = "db-f1-micro"  # minimal, low-cost tier for dev/test
    ip_configuration {
      ipv4_enabled = true
    }
  }

  # Optional: Turn off deletion protection for easy tear-down
  deletion_protection = false
}

resource "google_sql_database_instance" "prod-db" {
  name                 = "bhanufyi-prod-db"
  project              = "bhanufyi"
  region               = "us-east1"
  database_version     = "POSTGRES_15"

  settings {
    tier = "db-f1-micro"  # minimal, low-cost tier for dev/test
    ip_configuration {
      ipv4_enabled = true
    }
  }

  # Optional: Turn off deletion protection for easy tear-down
  deletion_protection = false
}


resource "google_sql_user" "dev-db-user" {
  name      = "bhanu"
  instance  = google_sql_database_instance.dev-db.name
  project   = "bhanufyi"
  password  = data.google_secret_manager_secret_version_access.dev_db_password.secret_data
}

resource "google_sql_user" "prod-db-user" {
  name      = "bhanu"
  instance  = google_sql_database_instance.prod-db.name
  project   = "bhanufyi"
  password  = data.google_secret_manager_secret_version_access.prod_db_password.secret_data
}


