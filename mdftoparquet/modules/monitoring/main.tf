/**
 * Monitoring Module for MDF4-to-Parquet Pipeline in Azure
 * Creates a Logic App to monitor the event queue and send email notifications
 */

# Get the storage account details from the main module
data "azurerm_storage_account" "existing" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create Logic App to monitor the queue and send emails
resource "azurerm_logic_app_workflow" "event_notification" {
  name                = "logicapp-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Output instructions for setting up Logic App in the Azure Portal
output "logic_app_setup" {
  value = <<EOT
To set up the Logic App for email notifications:
1. Go to Azure Portal > Logic Apps > logicapp-${var.unique_id}
2. Click "Edit" to open the designer
3. Add a trigger for Azure Queue Storage - "When messages are available in a queue"
4. Use the following queue information:
   - Storage Account: ${data.azurerm_storage_account.existing.name}
   - Queue: ${var.event_queue_name}
5. Add a Parse JSON action to parse the message:
   - Content: @{base64ToString(triggerBody()?['ContentData'])}
   - Schema: { "properties": { "message": { "type": "string" }, "subject": { "type": "string" }, "timestamp": { "type": "string" } }, "type": "object" }
6. Add an Office 365 Outlook action to send an email to: ${var.notification_email}
EOT
}

