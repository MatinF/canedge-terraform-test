/**
* Pub/Sub module for event notifications
*/

# Create a Pub/Sub topic for event notifications
resource "google_pubsub_topic" "notification_topic" {
  name = "${var.unique_id}-notifications"
  
  labels = {
    goog-terraform-provisioned = "true"
    purpose = "canedge-event-notifications"
  }
}

# Create an email subscription for the topic
resource "google_pubsub_subscription" "email_subscription" {
  name  = "${var.unique_id}-email-subscription"
  topic = google_pubsub_topic.notification_topic.name
  
  push_config {
    push_endpoint = "https://pubsub.googleapis.com/v1/projects/${var.project}/topics/${google_pubsub_topic.notification_topic.name}:publish"
    
    # This attribute enables the Pub/Sub email delivery feature
    attributes = {
      "email" = var.notification_email
    }
  }
  
  # Default message retention - 7 days
  message_retention_duration = "604800s"
  
  # Retry policy for failed delivery attempts
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
  
  labels = {
    goog-terraform-provisioned = "true"
  }
}
