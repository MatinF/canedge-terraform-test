/**
* Outputs for the Monitoring Module
*/

output "metric_id" {
  description = "ID of the created logging metric"
  value       = google_logging_metric.mdf_to_parquet_event_metric.id
}

output "alert_policy_id" {
  description = "ID of the created alert policy"
  value       = google_monitoring_alert_policy.mdf_to_parquet_event_alert.id
}

output "notification_channel_id" {
  description = "ID of the created notification channel"
  value       = google_monitoring_notification_channel.email_channel.id
}
