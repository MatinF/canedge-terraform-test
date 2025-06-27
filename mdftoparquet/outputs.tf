/**
* Output variables for the CANedge MDF-to-Parquet Terraform Stack for Azure
*/

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = data.azurerm_storage_account.existing.name
}

output "input_container_name" {
  description = "Name of the input container where MDF files are uploaded"
  value       = var.input_container_name
}

output "output_container_name" {
  description = "Name of the output container for Parquet files"
  value       = module.output_container.container_name
}


output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = module.cloud_function.function_app_name
}

output "function_app_url" {
  description = "URL of the Azure Function App"
  value       = "https://${module.cloud_function.function_app_default_hostname}"
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = module.cloud_function.application_insights_name
}

output "eventgrid_topic_name" {
  description = "Name of the Event Grid System Topic"
  value       = module.cloud_function.eventgrid_topic_name
}

output "eventgrid_subscription_name" {
  description = "Name of the Event Grid Subscription"
  value       = module.cloud_function.eventgrid_subscription_name
}
