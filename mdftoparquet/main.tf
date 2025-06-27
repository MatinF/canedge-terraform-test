/**
* Main Terraform configuration for the CANedge MDF-to-Parquet pipeline on Azure
* This creates a serverless architecture to convert MDF files to Parquet format using Azure Functions
* The code is organized in modules for better maintainability
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
  }
  # Store Terraform state in the input container
  backend "azurerm" {
    # These values will be provided via backend-config in the deployment script
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Get the existing storage account from the input container
data "azurerm_storage_account" "existing" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Generate SAS token for accessing the function ZIP file
data "azurerm_storage_account_sas" "function_sas" {
  connection_string = data.azurerm_storage_account.existing.primary_connection_string
  https_only        = true
  
  resource_types {
    service   = false
    container = false
    object    = true
  }
  
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  
  start  = timestamp()
  expiry = timeadd(timestamp(), "8h") # 8 hours expiry for deployment
  
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

# Define local variables
locals {
  output_container_name = "${var.input_container_name}-parquet"
}

# Create the output container module
module "output_container" {
  source = "./modules/output_container"
  
  output_container_name = local.output_container_name
  storage_account_id    = data.azurerm_storage_account.existing.id
}

# Create the cloud function module
module "cloud_function" {
  source = "./modules/cloud_function"
  
  unique_id                = var.unique_id
  location                 = var.location
  resource_group_name      = var.resource_group_name
  storage_account_name     = var.storage_account_name
  storage_account_id       = data.azurerm_storage_account.existing.id
  storage_account_access_key = data.azurerm_storage_account.existing.primary_access_key
  storage_connection_string = data.azurerm_storage_account.existing.primary_connection_string
  input_container_name     = var.input_container_name
  output_container_name    = module.output_container.container_name
  function_zip_name        = var.function_zip_name
  function_app_name        = var.function_app_name
  email_address            = var.email_address
  sas_token                = data.azurerm_storage_account_sas.function_sas.sas
}
  

