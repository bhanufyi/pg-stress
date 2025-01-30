resource "google_pubsub_topic" "topics" {
  for_each = toset(["users","phone"])
  name     = "prefix-${each.value}"
}

resource "google_pubsub_subscription" "email_sequences_subscription" {
  name                 = "sequences-created"
  topic                = google_pubsub_topic.topics["users"].name
  ack_deadline_seconds = 30

  push_config {
    push_endpoint = "https://n8n-922801875648.us-east1.run.app/webhook/sequence-created"
  }
  message_retention_duration = "604800s"
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
#   filter = "attributes.operation = \"INSERT\""
}