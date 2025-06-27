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

# Get output container as an existing Data Lake Gen2 filesystem
data "azurerm_storage_data_lake_gen2_filesystem" "output" {
  name               = "${var.input_container_name}-parquet"
  storage_account_id = data.azurerm_storage_account.storage.id
}

# Synapse workspace and resources
module "synapse" {
  source                            = "./modules/synapse"
  resource_group_name               = var.resource_group_name
  location                          = data.azurerm_resource_group.rg.location
  unique_id                         = var.unique_id
  storage_account_name              = var.storage_account_name
  storage_data_lake_gen2_filesystem_id = data.azurerm_storage_data_lake_gen2_filesystem.output.id
  dataset_name                      = var.dataset_name
}
