/**
* CANedge Input Container Creation on Azure
* Creates an input container with appropriate settings for CANedge data
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }
  
  # Using local state for input container creation
  # This keeps the deployment simple without requiring remote state management
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Create the resource group if it doesn't exist
resource "azurerm_resource_group" "rg" {
  count    = 1
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    # Prevent destruction of existing resource group
    prevent_destroy = false
    # Don't replace if it already exists
    ignore_changes = all
  }
}

# Create a storage account if it doesn't exist
resource "azurerm_storage_account" "storage" {
  count                    = 1
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg[0].name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # Enable hierarchical namespace for Azure Data Lake Storage Gen2
  is_hns_enabled           = true
  
  depends_on = [azurerm_resource_group.rg]

  lifecycle {
    # Prevent destruction of an existing storage account
    prevent_destroy = false
    # Don't update the storage account if it already exists
    ignore_changes = [
      is_hns_enabled,
      account_tier,
      account_replication_type,
      blob_properties
    ]
  }
}

# Create a storage container for CANedge data
resource "azurerm_storage_container" "input_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.storage[0].id
  container_access_type = "private"
}

# Generate SAS token with appropriate permissions - valid for 10 years
resource "time_rotating" "sas_expiry" {
  rotation_years = 10 # 10-year validity for the SAS token
}

data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.storage[0].primary_connection_string
  https_only        = false # Allow both HTTP and HTTPS access
  
  resource_types {
    service   = true  # Allow access to service-level APIs
    container = true  # Allow access to container-level APIs
    object    = true  # Allow access to object-level APIs
  }
  
  services {
    blob  = true  # Access to blob storage
    queue = true  # Access to queues if needed
    table = true  # Access to tables if needed
    file  = true  # Access to files if needed
  }
  
  start  = timestamp()
  expiry = time_rotating.sas_expiry.rotation_rfc3339
  
  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true  # Allow processing operations
    tag     = true  # Allow tagging objects
    filter  = true  # Allow filter operations
  }
}
