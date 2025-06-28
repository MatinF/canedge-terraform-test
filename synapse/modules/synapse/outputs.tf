output "synapse_workspace_id" {
  description = "The ID of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.id
}

output "synapse_workspace_name" {
  description = "The name of the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.name
}

output "sql_server_endpoint" {
  description = "The SQL Server endpoint for the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.connectivity_endpoints["sql"]
}

output "serverless_sql_endpoint" {
  description = "The Serverless SQL endpoint for the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.connectivity_endpoints["sqlOnDemand"]
}

output "web_endpoint" {
  description = "The Web endpoint for the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.connectivity_endpoints["web"]
}

output "sql_admin_password" {
  description = "The SQL admin password for the Synapse workspace"
  value       = random_password.sql_password.result
  sensitive   = true
}

output "sql_password" {
  description = "The SQL admin password for the Synapse workspace (alias for container app job)"
  value       = random_password.sql_password.result
  sensitive   = true
}

output "synapse_workspace_endpoint" {
  description = "The SQL Server endpoint for the Synapse workspace"
  value       = azurerm_synapse_workspace.synapse.connectivity_endpoints["sql"]
}
