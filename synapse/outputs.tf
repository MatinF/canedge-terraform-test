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

When to run the job:
- After adding new device data to the data lake
- After adding new message types to existing devices
- When the structure of your Parquet data changes

To manually execute the job, run the following Azure CLI command:
${module.container_app_job.execution_command}

You can also run the job directly from the Azure Portal:
1. Go to Azure Portal > Container Apps > Jobs
2. Select the "${module.container_app_job.job_name}" job
3. Click "Start execution" button
4. View the logs to monitor job progress

The job will create tables in the following format:
- Table name: tbl_{device}_{message}
- Example: tbl_93118DA3_CAN1

After the job completes, you can query these tables in Synapse Studio.
EOF
}
