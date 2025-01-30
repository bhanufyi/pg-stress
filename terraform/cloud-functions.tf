
# # -------------------------------------------------------------------
# # Archive your function's source code from the functions folder.
# # This example assumes you have precompiled your TS -> JS into a 'dist' folder.
# # If you're not doing that, you can just zip the entire functions folder,
# # but ensure all necessary dependencies are included (node_modules, etc.).
# # -------------------------------------------------------------------
# data "archive_file" "function_zip" {
#   type        = "zip"

#   # If you're compiling TypeScript -> JavaScript, 
#   # then reference the dist folder to reduce final artifact size.
#   source_dir  = "${path.root}/../functions" 
#   output_path = "${path.module}/function_source.zip"
# }

# # -------------------------------------------------------------------
# # Create a temporary bucket to store the function's source code zip.
# # (If you already have a suitable bucket, you can skip creating a new one.)
# # -------------------------------------------------------------------

# resource "google_storage_bucket_object" "function_archive" {
#   name   = "function_source.zip"
#   bucket = "rs_val20"
#   source = data.archive_file.function_zip.output_path
# }

# # -------------------------------------------------------------------
# # Deploy a 1st generation Cloud Function with an HTTP trigger.
# # -------------------------------------------------------------------
# resource "google_cloudfunctions2_function" "http_function" {
#   name        = "bhanufyi-events-function"
#   description = "Publishes messages to PubSub based on incoming HTTP requests"
#   location =  local.region

#   build_config {
#     runtime =  "nodejs20"
#     entry_point = "pubsubFunction"
#     # If you need environment variables, specify them here:
#     environment_variables = {
#         EVENTS_FUNCTION_SECRET = "function-secret" # should secret manger secret TODO
#     }
#     source {
#       storage_source {
#         bucket = "rs_val20"
#         object =  google_storage_bucket_object.function_archive.name
#       }
#     }
#   }

#   service_config {
#     min_instance_count = 1
#     available_memory = "256M"
#     timeout_seconds = 60
#     service_account_email = "ai-ml-discover@bhanufyi.iam.gserviceaccount.com"
#   }


# }

# resource "google_cloudfunctions2_function_iam_member" "run_invoker" {
#   project        = local.project
#   location         = local.region
#   cloud_function = google_cloudfunctions2_function.http_function.name
#   role           = "roles/cloudfunctions.invoker"
#   member         = "serviceAccount:ai-ml-discover@bhanufyi.iam.gserviceaccount.com"
# }

