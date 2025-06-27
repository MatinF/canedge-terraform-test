terraform {
  required_version = ">= 0.14.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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

# Get existing resource group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Get existing storage account
data "azurerm_storage_account" "storage" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Define the output container name and construct the filesystem ID
locals {
  output_container_name = "${var.input_container_name}-parquet"
  
  # Construct the filesystem ID using the known format for Azure Data Lake Gen2
  # This is needed because the container already exists and we can't create it again
  storage_data_lake_gen2_filesystem_id = "${data.azurerm_storage_account.storage.id}/blobServices/default/containers/${local.output_container_name}"
}


# Synapse workspace and resources
module "synapse" {
  source                            = "./modules/synapse"
  resource_group_name               = var.resource_group_name
  location                          = data.azurerm_resource_group.rg.location
  unique_id                         = var.unique_id
  storage_account_name              = var.storage_account_name
  storage_data_lake_gen2_filesystem_id = local.storage_data_lake_gen2_filesystem_id
  dataset_name                      = var.dataset_name
}
