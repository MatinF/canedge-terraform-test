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
  # Explicitly set provider to use the subscription ID for all operations
  skip_provider_registration = true
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

# Define the output container name
locals {
  output_container_name = "${var.input_container_name}-parquet"
}

# Import the existing data lake filesystem as a managed resource
# This allows us to reference it without trying to recreate it
resource "azurerm_storage_data_lake_gen2_filesystem" "output" {
  name               = local.output_container_name
  storage_account_id = data.azurerm_storage_account.storage.id

  # Important: tell Terraform this resource already exists
  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}

# Synapse workspace and resources
module "synapse" {
  source                            = "./modules/synapse"
  resource_group_name               = var.resource_group_name
  location                          = data.azurerm_resource_group.rg.location
  unique_id                         = var.unique_id
  storage_account_name              = var.storage_account_name
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.output.id
  dataset_name                      = var.dataset_name
}
