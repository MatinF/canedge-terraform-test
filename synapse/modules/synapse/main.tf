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
  managed_virtual_network_enabled      = false
  public_network_access_enabled        = true

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

# Get the container reference to grant permissions specifically at container level
data "azurerm_storage_container" "output_container" {
  name                 = var.output_container_name
  storage_account_name = var.storage_account_name
}

# Grant the Synapse workspace Storage Blob Data Contributor access on the specific container
# This matches the permission model from the manual deployment
resource "azurerm_role_assignment" "synapse_container_contributor" {
  scope                = "${data.azurerm_storage_account.synapse_storage.id}/blobServices/default/containers/${var.output_container_name}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Allow management from client IP addresses (can be adjusted as needed)
resource "azurerm_synapse_firewall_rule" "client_ip" {
  name                 = "ClientIPAccess"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"  # Replace with specific IP range if needed
  end_ip_address       = "255.255.255.255" # Replace with specific IP range if needed
}

# Set the Microsoft Entra admin using the dedicated resource instead of the deprecated block
resource "azurerm_synapse_workspace_aad_admin" "admin" {
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  login                = "AzureAD Admin"  # This is a display name shown in portal
  object_id            = var.current_user_object_id
  tenant_id            = var.tenant_id
}

# Output moved to outputs.tf

