output "logic_app_id" {
  description = "The ID of the created Logic App"
  value       = azurerm_logic_app_workflow.event_notification.id
}

output "logic_app_name" {
  description = "The name of the Logic App for queue-based alerts"
  value       = azurerm_logic_app_workflow.event_notification.name
}
