/**
 * Monitoring Module for MDF4-to-Parquet Pipeline in Azure
 * Creates Azure Monitor resources for log-based alerting
 */

# Action Group for sending email notifications
resource "azurerm_monitor_action_group" "email_alerts" {
  name                = "email-alerts-${var.unique_id}"
  resource_group_name = var.resource_group_name
  short_name          = "emailalrt"

  email_receiver {
    name                    = "admin"
    email_address           = var.notification_email
    use_common_alert_schema = true
  }
}

# Alert rule for NEW EVENT log pattern
resource "azurerm_monitor_scheduled_query_rules_alert" "new_event_alert" {
  name                = "new-event-alert-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  action {
    action_group           = [azurerm_monitor_action_group.email_alerts.id]
    email_subject          = "CANedge Log Processing Event"
  }

  data_source_id = var.application_insights_id
  description    = "Alert when NEW EVENT is detected in function logs"
  enabled        = true

  # Query to detect the specific log pattern
  query       = <<-QUERY
  traces
  | where message contains "NEW EVENT"
  | project timestamp, message
  QUERY
  
  severity    = 1
  frequency   = 5  # Check every 5 minutes
  time_window = 10 # Look at the past 10 minutes
  
  # Trigger if any results are found
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}

# Alert rule for ERROR logs
resource "azurerm_monitor_scheduled_query_rules_alert" "error_alert" {
  name                = "error-alert-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  action {
    action_group           = [azurerm_monitor_action_group.email_alerts.id]
    email_subject          = "CANedge Log Processing Error"
  }

  data_source_id = var.application_insights_id
  description    = "Alert when errors are detected in function logs"
  enabled        = true

  # Query to detect error logs
  query       = <<-QUERY
  traces
  | where severityLevel == 3
  | project timestamp, message
  QUERY
  
  severity    = 1
  frequency   = 5  # Check every 5 minutes
  time_window = 10 # Look at the past 10 minutes
  
  # Trigger if any results are found
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
