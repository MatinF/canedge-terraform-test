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

  # Add registry credentials for GitHub Container Registry
  registry {
    server               = "ghcr.io"
    username             = var.github_username
    password_secret_name = "github-token"
  }
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
  name                         = "${var.job_name}-${var.unique_id}"
  container_app_environment_id = azurerm_container_app_environment.job_env.id
  resource_group_name          = var.resource_group_name
  location                     = var.location
  tags                         = var.tags
  
  # Required field
  replica_timeout_in_seconds   = 1800
  
  # Manual trigger configuration
  manual_trigger_config {
    parallelism      = 1
    replica_completion_count = 1
  }
  
  template {
    container {
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
        secret_name = "storage-connection-string"
      }
      
      env {
        name  = "SYNAPSE_SERVER"
        value = var.synapse_server
      }
      
      env {
        name  = "SYNAPSE_PASSWORD"
        value = var.synapse_sql_password
        secret_name = "synapse-password"
      }
      
      env {
        name  = "MASTER_KEY_PASSWORD"
        value = random_password.master_key.result
        secret_name = "master-key-password"
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
  }
  
  # Secrets configuration
  secret {
    name  = "storage-connection-string"
    value = "DefaultEndpointsProtocol=https;AccountName=${var.storage_account_name};AccountKey=${data.azurerm_storage_account.storage.primary_access_key};EndpointSuffix=core.windows.net"
  }
  
  secret {
    name  = "synapse-password"
    value = var.synapse_sql_password
  }
  
  secret {
    name  = "master-key-password"
    value = random_password.master_key.result
  }

  # GitHub Container Registry authentication token
  secret {
    name  = "github-token"
    value = var.github_token
  }
}
