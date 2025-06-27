output "synapse_workspace_name" {
  description = "The name of the Synapse workspace"
  value       = module.synapse.synapse_workspace_name
}

output "sql_server_endpoint" {
  description = "The SQL Server endpoint for the Synapse workspace"
  value       = module.synapse.sql_server_endpoint
}

output "serverless_sql_endpoint" {
  description = "The Serverless SQL endpoint for the Synapse workspace"
  value       = module.synapse.serverless_sql_endpoint
}

output "web_endpoint" {
  description = "The Web endpoint for the Synapse workspace"
  value       = module.synapse.web_endpoint
}

output "synapse_connection_details" {
  description = "Connection details for Synapse"
  value = <<EOF
  
The following details can be used for connecting to the Synapse deployment: 

Name: Microsoft SQL Server
Host: ${module.synapse.serverless_sql_endpoint}
Database: ${var.dataset_name}
Authentication: SQL Server Authentication
User: sqladminuser
Password: ${module.synapse.sql_admin_password}
Min time interval: 1ms
EOF
  sensitive = true
}
