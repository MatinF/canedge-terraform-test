output "topic_id" {
  description = "ID of the created Pub/Sub topic"
  value       = google_pubsub_topic.notification_topic.id
}

output "topic_name" {
  description = "Name of the created Pub/Sub topic"
  value       = google_pubsub_topic.notification_topic.name
}

output "topic_path" {
  description = "Full resource path of the Pub/Sub topic, equivalent to an SNS ARN in AWS"
  value       = "projects/${var.project}/topics/${google_pubsub_topic.notification_topic.name}"
}
