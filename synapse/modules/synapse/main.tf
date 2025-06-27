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

# Create output to expose the endpoint and password
output "serverless_sql_endpoint" {
  value = azurerm_synapse_workspace.synapse.connectivity_endpoints["sqlOnDemand"]
}

output "sql_password" {
  value     = random_password.sql_password.result
  sensitive = true
}
