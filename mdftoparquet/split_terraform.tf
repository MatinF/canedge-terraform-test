/**
 * Split Terraform configuration for the "Terraform Sandwich" approach
 * This separates the Event Grid subscription from the main infrastructure
 * to ensure the Azure Function is fully deployed before creating the subscription
 *
 * The include_event_grid_subscription variable is defined in variables.tf
 */

# The Event Grid subscription resource moved from main.tf
resource "azurerm_eventgrid_system_topic_event_subscription" "input_events" {
  # Only create this resource if include_event_grid_subscription is true
  count               = var.include_event_grid_subscription ? 1 : 0
  
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
