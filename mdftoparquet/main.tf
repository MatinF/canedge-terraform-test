/**
* Main Terraform configuration for the CANedge MDF-to-Parquet pipeline on Azure
* This creates a serverless architecture to convert MDF files to Parquet format using Azure Functions
* Using Option 2: zip_deploy_file with ZIP downloaded from input container
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

# Create storage account for output container if it doesn't exist
# Note: We're using the existing storage account from the input container
data "azurerm_storage_account" "existing" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create output container for Parquet files with name derived from input container
locals {
  output_container_name = "${var.input_container_name}-parquet"
}

resource "azurerm_storage_container" "output_container" {
  name                  = local.output_container_name
  storage_account_id    = data.azurerm_storage_account.existing.id
  container_access_type = "private"
  
  # Prevent destruction of existing container
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      storage_account_id,
      container_access_type
    ]
  }
}

# Create a storage queue for notifications
resource "azurerm_storage_queue" "notification_queue" {
  name                 = var.notification_queue_name
  storage_account_name = data.azurerm_storage_account.existing.name
  
  # Prevent destruction of existing queue
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      storage_account_name
    ]
  }
}

# Create App Service Plan for Azure Functions (Consumption plan)
resource "azurerm_service_plan" "function_app_plan" {
  name                = "plan-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
  
  # Prevent destruction of existing plan
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      location,
      resource_group_name,
      os_type,
      sku_name
    ]
  }
}

# Generate a random string for function app name if not provided
locals {
  function_app_name = var.function_app_name != "" ? var.function_app_name : "mdftoparquet-${var.unique_id}"
}

# Download the function ZIP from blob storage to local temp file
resource "null_resource" "download_function_zip" {
  triggers = {
    function_zip_name = var.function_zip_name
    storage_account   = var.storage_account_name
    container         = var.input_container_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Create temp directory if it doesn't exist
      mkdir -p /tmp/terraform-functions
      
      # Download the ZIP file from blob storage
      az storage blob download \
        --account-name ${var.storage_account_name} \
        --container-name ${var.input_container_name} \
        --name ${var.function_zip_name} \
        --file /tmp/terraform-functions/${var.function_zip_name} \
        --auth-mode login
    EOT
  }

  # Clean up on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f /tmp/terraform-functions/${self.triggers.function_zip_name}"
  }
}

# Create Azure Function App using zip_deploy_file
resource "azurerm_linux_function_app" "function_app" {
  name                       = local.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.function_app_plan.id
  storage_account_name       = data.azurerm_storage_account.existing.name
  storage_account_access_key = data.azurerm_storage_account.existing.primary_access_key
  
  # Use zip_deploy_file instead of WEBSITE_RUN_FROM_PACKAGE
  zip_deploy_file = "/tmp/terraform-functions/${var.function_zip_name}"
  
  # Configure app settings for Python function (without WEBSITE_RUN_FROM_PACKAGE)
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "FUNCTIONS_EXTENSION_VERSION"           = "~4"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"       = "true"
    "ENABLE_ORYX_BUILD"                     = "true"
    "BUILD_FLAGS"                           = "UseExpressBuild"
    "XDG_CACHE_HOME"                        = "/tmp/.cache"
    "PYTHON_ISOLATE_WORKER_DEPENDENCIES"   = "1"
    "AzureWebJobsStorage"                   = data.azurerm_storage_account.existing.primary_connection_string
    "StorageConnectionString"               = data.azurerm_storage_account.existing.primary_connection_string
    "InputContainerName"                    = var.input_container_name
    "OutputContainerName"                   = local.output_container_name
    "NotificationQueueName"                 = var.notification_queue_name
    "NotificationEmail"                     = var.email_address
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights.connection_string
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
    
    application_insights_connection_string = azurerm_application_insights.insights.connection_string
    application_insights_key               = azurerm_application_insights.insights.instrumentation_key
  }

  # Ensure the ZIP file is downloaded before deploying
  depends_on = [null_resource.download_function_zip]
}

# Create Application Insights for monitoring
resource "azurerm_application_insights" "insights" {
  name                = "appinsights-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  
  # Prevent destruction of existing insights
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      location,
      resource_group_name,
      application_type
    ]
  }
}

# Create Event Grid System Topic for Blob Storage events
resource "azurerm_eventgrid_system_topic" "storage_events" {
  name                   = "evgt-${var.unique_id}"
  location               = data.azurerm_storage_account.existing.location
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = data.azurerm_storage_account.existing.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

# Get the function app host keys (this will only be available after the function app is deployed)
data "azurerm_function_app_host_keys" "keys" {
  name                = azurerm_linux_function_app.function_app.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_linux_function_app.function_app]
}

# Create Event Grid Subscription for input container events
resource "azurerm_eventgrid_system_topic_event_subscription" "input_events" {
  name                = "evgs-${var.unique_id}"
  system_topic        = azurerm_eventgrid_system_topic.storage_events.name
  resource_group_name = var.resource_group_name
  
  # Use standard Event Grid Schema
  event_delivery_schema = "EventGridSchema"

  included_event_types = [
    "Microsoft.Storage.BlobCreated"
  ]

  # Filter for blob path prefix - common for all MF files
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.input_container_name}/blobs/"
    case_sensitive      = false
  }

  # Case-insensitive MF file extension matching using advanced filters
  # This allows matching multiple extensions: MF4, MFC, MFE, MFM 
  advanced_filter {
    string_ends_with {
      key = "subject"
      values = [".MF4", ".MFC", ".MFE", ".MFM"]
    }
  }
  
  # Use Azure Function endpoint to directly trigger the function
  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.function_app.id}/functions/ProcessMdfToParquet"
    max_events_per_batch = 1
    preferred_batch_size_in_kilobytes = 64
  }

  # Disable retries - if function fails, don't retry
  retry_policy {
    max_delivery_attempts = 1
    event_time_to_live    = 1
  }
  
  # Wait for function app to be created before creating event subscription
  depends_on = [
    azurerm_linux_function_app.function_app,
    data.azurerm_function_app_host_keys.keys
  ]
  
  # Lifecycle management for Event Grid subscription
  lifecycle {
    ignore_changes = [
      webhook_endpoint
    ]
  }
}