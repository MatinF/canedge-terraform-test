/**
* Output variables for the CANedge Input Container Terraform Stack for Azure
*/

output "container_name" {
  description = "Name of the created input container"
  value       = azurerm_storage_container.input_container.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.storage[0].name
}

output "region" {
  description = "Region where the resources were created"
  value       = var.location
}

output "access_key" {
  description = "Access key for the storage account"
  value       = azurerm_storage_account.storage[0].primary_access_key
  sensitive   = true
}

output "sas_token" {
  description = "SAS token for the storage account"
  value       = data.azurerm_storage_account_sas.sas.sas
  sensitive   = true
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}
