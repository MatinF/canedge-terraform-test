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
  
  # Set short acknowledgement deadline to fail quickly if there's an issue
  ack_deadline_seconds = 10
  
  # Minimal retry policy - short backoff and only retry for a brief period
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "60s" # Limit maximum backoff to just 1 minute
  }
  
  # Set a short expiration period for messages to prevent long retry cycles
  expiration_policy {
    ttl = "300s" # 5 minutes maximum lifetime for undelivered messages
  }
  
  labels = {
    goog-terraform-provisioned = "true"
  }
}
