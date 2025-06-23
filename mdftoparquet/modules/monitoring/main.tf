/**
* Monitoring Module for MDF4-to-Parquet Pipeline
* Creates logging-based metrics and alert policies
*/

# Create a log-based metric that tracks when "NEW EVENT" appears in logs
resource "google_logging_metric" "mdf_to_parquet_event_metric" {
  name        = "mdf_to_parquet_event_metric"
  filter      = "resource.type=\"cloud_function\" AND resource.labels.function_name=\"${var.function_name}\" AND textPayload:\"NEW EVENT\""
  description = "Tracks occurrences of \"NEW EVENT\" in MDF-to-Parquet function logs"
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    display_name = "MDF-to-Parquet Events"
  }
  
  label_extractors = {}
}

# Create a notification channel for email alerts
resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "${var.unique_id}-email-alerts"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
  
  description = "Email notification channel for MDF-to-Parquet alerts"
}

# Create an alerting policy that triggers when the metric is detected
resource "google_monitoring_alert_policy" "mdf_to_parquet_event_alert" {
  display_name = "mdf_to_parquet_event_alert"
  combiner     = "OR"
  
  conditions {
    display_name = "MDF-to-Parquet Event Detected"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.mdf_to_parquet_event_metric.name}\" AND resource.type=\"cloud_function\""
      duration        = "0s"  # Alert immediately when event is detected
      comparison      = "COMPARISON_GT"
      threshold_value = 0     # Alert on any occurrence
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
      
      trigger {
        count = 1  # Trigger after a single occurrence
      }
    }
  }
  
  documentation {
    content = "The Cloud Function for MDF4-to-Parquet conversion has detected a new event."
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email_channel.name
  ]
}
