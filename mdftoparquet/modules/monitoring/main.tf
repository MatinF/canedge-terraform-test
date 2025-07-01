/**
 * Monitoring Module for MDF4-to-Parquet Pipeline in Azure
 * Creates Logic App to monitor queue messages and send email notifications
 */

# Create Logic App to monitor the queue and send emails
resource "azurerm_logic_app_workflow" "event_notification" {
  name                = "logicapp-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Get the storage account details from the main module
data "azurerm_storage_account" "existing" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create a Logic App connection to Azure Storage Queue
resource "azurerm_api_connection" "storage" {
  name                = "storage-connection-${var.unique_id}"
  resource_group_name = var.resource_group_name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurequeues"
  display_name        = "Azure Storage Queue Connection"
  
  parameter_values = {
    "storageAccountName" = data.azurerm_storage_account.existing.name
    "accessKey"          = data.azurerm_storage_account.existing.primary_access_key
  }
}



# For manual configuration post-deployment
# The Logic App will need to be configured in the Azure Portal
# with connections to Azure Queue and Office 365 Email

# Since queue-specific actions are hard to configure in Terraform directly,
# we'll provide deployment instructions in the output
output "logic_app_configuration_steps" {
  value = <<EOT
To complete Logic App setup:
1. Go to Azure Portal > Logic Apps > logicapp-${var.unique_id}
2. Click "Edit" to open Logic App Designer
3. Add a trigger: "When there are messages in a queue"
   - Select the Azure Storage Queue connection created by Terraform
   - Select the queue name: events-${var.unique_id}
   - Set polling interval to 3 minutes
4. Add an action: "Parse JSON"
   - Content: @{base64ToString(triggerBody()?['ContentData'])}
   - Schema: {
      "properties": {
        "message": { "type": "string" },
        "subject": { "type": "string" },
        "timestamp": { "type": "string" }
      },
      "type": "object"
    }
5. Add an action: "Send an email (Office 365 Outlook)"
   - Create or select an Office 365 connection
   - To: ${var.notification_email}
   - Subject: CANedge Alert: @{body('Parse_JSON')['subject']}
   - Body: <p>A new event was detected in your CANedge log processing pipeline:</p><p>@{body('Parse_JSON')['message']}</p><p>Event Time (UTC): @{body('Parse_JSON')['timestamp']}</p>
6. Save the Logic App
EOT
}

