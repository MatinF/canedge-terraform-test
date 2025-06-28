resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "_%@"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "synapse-${var.unique_id}"
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.storage_data_lake_gen2_filesystem_id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_password.sql_password.result

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    Application = "CANedge"
  }
}

# Get information about the storage account to assign permissions
data "azurerm_storage_account" "synapse_storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Grant the Synapse workspace Storage Blob Data Contributor access on the storage account
# This is required for Synapse to be able to read and write data
resource "azurerm_role_assignment" "synapse_storage_contributor" {
  scope                = data.azurerm_storage_account.synapse_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Grant the Synapse workspace Storage Blob Data Reader access to ensure it can read from blob storage
resource "azurerm_role_assignment" "synapse_storage_reader" {
  scope                = data.azurerm_storage_account.synapse_storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Create output (moved to outputs.tf)
output "sql_password" {
  value     = random_password.sql_password.result
  sensitive = true
}
