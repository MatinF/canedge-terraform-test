output "action_group_id" {
  description = "The ID of the created Monitor Action Group"
  value       = azurerm_monitor_action_group.email_alerts.id
}

output "event_alert_id" {
  description = "The ID of the event alert rule"
  value       = azurerm_monitor_scheduled_query_rules_alert.new_event_alert.id
}

output "error_alert_id" {
  description = "The ID of the error alert rule"
  value       = azurerm_monitor_scheduled_query_rules_alert.error_alert.id
}
