/**
* Cloud function module for the CANedge MDF-to-Parquet pipeline
* This creates the Azure Function App and related resources for processing MDF files
*/

# Generate a random UUID for each deployment to force updates
resource "random_uuid" "deployment_id" {}

# Application insights for monitoring
resource "azurerm_application_insights" "insights" {
  name                = "appinsights-${var.unique_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  
  # Prevent destruction of existing app insights
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

# Generate a SAS URL for downloading the function ZIP
locals {
  function_app_name = var.function_app_name != "" ? var.function_app_name : "mdftoparquet-${var.unique_id}"
  function_zip_path = "${path.root}/function-deploy-package.zip"
  download_url = "https://${var.storage_account_name}.blob.core.windows.net/${var.input_container_name}/${var.function_zip_name}${var.sas_token}"
  
  # Define base app settings for the function app
  base_app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"          = "python"
    "FUNCTIONS_EXTENSION_VERSION"       = "~4" # Latest version
    "SCM_DO_BUILD_DURING_DEPLOYMENT"   = true
    "ENABLE_ORYX_BUILD"                 = true
    "BUILD_FLAGS"                      = "UseExpressBuild"
    "XDG_CACHE_HOME"                   = "/tmp/.cache"
    "AzureWebJobsStorage"               = var.storage_connection_string
    "StorageConnectionString"           = var.storage_connection_string
    "InputContainerName"                = var.input_container_name
    "OutputContainerName"               = var.output_container_name
    "NotificationEmail"                 = var.email_address
    "APPINSIGHTS_INSTRUMENTATIONKEY"    = azurerm_application_insights.insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.insights.connection_string
    "PYTHON_ENABLE_WORKER_EXTENSIONS"   = "1"
    "AzureWebJobsFeatureFlags"          = "EnableWorkerIndexing"
    # Add the ZIP file name to app settings to force deployment when it changes
    "FUNCTION_ZIP_NAME"                = var.function_zip_name
    # Add a unique deployment ID to force redeployment
    "DEPLOYMENT_ID"                    = random_uuid.deployment_id.result
    # Add a timestamp to force redeployment
    "DEPLOYMENT_TIMESTAMP"             = timestamp()
  }
}

# Use null_resource to download the function ZIP from blob storage
resource "null_resource" "download_function_zip" {
  # This will force the download to happen on every apply
  triggers = {
    # Using the function ZIP name as a trigger ensures it runs when the zip name changes
    function_zip_name = var.function_zip_name
    # Additional timestamp trigger to force refresh on each apply
    timestamp = timestamp()
  }

  # Use curl to download the file (works in both Linux and Windows with Git Bash/WSL)
  provisioner "local-exec" {
    command = "curl -L -o ${local.function_zip_path} \"${local.download_url}\""
  }
}

# Create the Linux Function App resource
resource "azurerm_linux_function_app" "function_app" {
  name                       = local.function_app_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.function_app_plan.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  site_config {
    application_stack {
      python_version = "3.11"
    }
    application_insights_connection_string = azurerm_application_insights.insights.connection_string
    application_insights_key               = azurerm_application_insights.insights.instrumentation_key
  }
  
  app_settings = local.base_app_settings
  
  # Use the downloaded ZIP file for deployment
  zip_deploy_file = local.function_zip_path
  
  # Create system-assigned managed identity for the function
  identity {
    type = "SystemAssigned"
  }
  
  # Prevent destruction of existing function app but allow updates
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      location,
      resource_group_name,
      storage_account_name,
      storage_account_access_key,
    ]
    replace_triggered_by = [
      # Force replacement of the function app when the ZIP file changes
      null_resource.download_function_zip
    ]
  }
  
  depends_on = [
    null_resource.download_function_zip
  ]
}

# Setup Event Grid trigger for the Function App
resource "azurerm_eventgrid_system_topic" "storage_events" {
  name                   = "evgt-${var.unique_id}"
  location               = var.location
  resource_group_name    = var.resource_group_name
  source_arm_resource_id = var.storage_account_id
  topic_type             = "Microsoft.Storage.StorageAccounts"
  
  # Prevent destruction of existing event grid topic
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      location,
      resource_group_name,
      source_arm_resource_id,
      topic_type
    ]
  }
}

resource "azurerm_eventgrid_system_topic_event_subscription" "input_events" {
  name                = "evgs-${var.unique_id}"
  system_topic        = azurerm_eventgrid_system_topic.storage_events.name
  resource_group_name = var.resource_group_name
  
  included_event_types = ["Microsoft.Storage.BlobCreated"]
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.input_container_name}/blobs/"
  }
  
  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.function_app.id}/functions/ProcessMdfToParquet"
    max_events_per_batch = 1
    preferred_batch_size_in_kilobytes = 64
  }
  
  # Prevent destruction of existing event grid subscription
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      system_topic,
      resource_group_name
    ]
  }
}

# Use a null_resource to restart the function after deployment
resource "null_resource" "restart_function_app" {
  # This will force the restart to happen on every apply
  triggers = {
    deployment_id = random_uuid.deployment_id.result
    function_zip_name = var.function_zip_name
    timestamp = timestamp()
  }

  # Run az CLI command to restart the function app
  provisioner "local-exec" {
    command = "az functionapp restart --name ${azurerm_linux_function_app.function_app.name} --resource-group ${var.resource_group_name}"
  }

  depends_on = [
    azurerm_linux_function_app.function_app,
    null_resource.download_function_zip
  ]
}
