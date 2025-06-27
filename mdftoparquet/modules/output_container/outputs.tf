/**
* Outputs for the output container module
*/

output "container_name" {
  description = "Name of the output container for Parquet files"
  value       = azurerm_storage_container.output_container.name
}

output "container_id" {
  description = "Resource ID of the output container"
  value       = azurerm_storage_container.output_container.id
}
