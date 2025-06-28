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
  
  aad_admin {
    login     = "AzureAD Admin"
    object_id = var.current_user_object_id
    tenant_id = var.tenant_id
  }

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

# Grant the Synapse workspace Storage Blob Data Owner access on the storage account
# This provides full permissions needed for listing directories and reading files
resource "azurerm_role_assignment" "synapse_storage_owner" {
  scope                = data.azurerm_storage_account.synapse_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}

# Add firewall rule to allow Azure services
resource "azurerm_synapse_firewall_rule" "allow_azure" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

# Add firewall rule to allow client access from any IP
# This is needed for development/testing - restrict in production
resource "azurerm_synapse_firewall_rule" "allow_all" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# Create output (moved to outputs.tf)
output "sql_password" {
  value     = random_password.sql_password.result
  sensitive = true
}
