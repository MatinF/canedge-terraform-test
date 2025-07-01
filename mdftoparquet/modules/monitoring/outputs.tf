output "logic_app_id" {
  description = "The ID of the created Logic App"
  value       = azurerm_resource_group_template_deployment.logic_app_workflow.id
}

output "logic_app_name" {
  description = "The name of the Logic App for queue-based alerts"
  value       = "logicapp-${var.unique_id}"
}
