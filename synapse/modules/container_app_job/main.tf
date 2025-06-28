# Create a Log Analytics workspace for Container App logs
resource "azurerm_log_analytics_workspace" "container_app" {
  name                = "log-${var.job_name}-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Create Container App Environment
resource "azurerm_container_app_environment" "job_env" {
  name                       = "env-${var.job_name}-${var.unique_id}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  tags                       = var.tags
}

# Generate a secure master key password
resource "random_password" "master_key" {
  length           = 16
  special          = true
  override_special = "_%@"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# Get Storage Account Key for connection string
data "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create Container App Job
resource "azurerm_container_app_job" "map_tables" {
  name                     = "${var.job_name}-${var.unique_id}"
  container_app_environment_id = azurerm_container_app_environment.job_env.id
  resource_group_name      = var.resource_group_name
  tags                     = var.tags
  
  template {
    containers {
      name   = "synapse-map-tables"
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory
      
      env {
        name  = "STORAGE_ACCOUNT"
        value = var.storage_account_name
      }
      
      env {
        name  = "CONTAINER_OUTPUT"
        value = var.output_container_name
      }
      
      env {
        name  = "STORAGE_CONNECTION_STRING"
        value = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${data.azurerm_storage_account.storage.primary_access_key};EndpointSuffix=core.windows.net"
        secure = true
      }
      
      env {
        name  = "SYNAPSE_SERVER"
        value = var.synapse_server
      }
      
      env {
        name  = "SYNAPSE_PASSWORD"
        value = var.synapse_sql_password
        secure = true
      }
      
      env {
        name  = "MASTER_KEY_PASSWORD"
        value = random_password.master_key.result
        secure = true
      }
      
      env {
        name  = "SYNAPSE_DATABASE"
        value = "parquetdatalake"
      }
      
      env {
        name  = "SYNAPSE_USER"
        value = "sqladminuser"
      }
    }
    
    max_retry_count = var.max_retry_count
  }
  
  trigger {
    type = var.trigger_type
  }
  
  # Ensure job creation doesn't block until first execution
  lifecycle {
    ignore_changes = [
      trigger.0.schedule
    ]
  }
}
