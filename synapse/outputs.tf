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

===== SYNAPSE CONNECTION DETAILS =====

Name: Microsoft SQL Server
Host: ${module.synapse.serverless_sql_endpoint}
Database: ${var.database_name}
Authentication: SQL Server Authentication
User: sqladminuser
Password: ${module.synapse.sql_admin_password}
Min time interval: 1ms
EOF
  sensitive = true
}

output "container_app_job_name" {
  description = "Name of the Container App Job for Synapse table mapping"
  value       = module.container_app_job.job_name
}

output "container_app_job_execution_command" {
  description = "Command to manually execute the Synapse table mapping job"
  value       = module.container_app_job.execution_command
}

output "synapse_table_mapper_instructions" {
  description = "Instructions for using the Synapse Table Mapper job"
  value = <<EOF

===== SYNAPSE TABLE MAPPER INSTRUCTIONS =====

The Synapse Table Mapper job is a containerized application that automatically
creates Synapse external tables for all device/message folders in your Parquet data lake.

It should be run if new devices/messages are added to your data lake:
1. Go to Azure Portal > Container Apps > Jobs
2. Select the "${module.container_app_job.job_name}" job
3. Click "Start execution" button (view logs to monitor progress)

EOF
}
