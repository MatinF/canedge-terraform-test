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
  managed_api_id      = "${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurequeues"
  display_name        = "Azure Storage Queue Connection"
  
  parameter_values = {
    "storageAccountName" = data.azurerm_storage_account.existing.name
    "accessKey"          = data.azurerm_storage_account.existing.primary_access_key
  }
}

# Create Logic App trigger and email action using ARM template
# Since Terraform doesn't have direct support for all Logic App actions/triggers,
# we're defining the workflow using raw JSON
resource "azurerm_resource_group_template_deployment" "logic_app_workflow" {
  name                = "logic-app-deployment-${var.unique_id}"
  resource_group_name = var.resource_group_name
  deployment_mode     = "Incremental"
  parameters_content  = jsonencode({
    "logicAppName"     = { "value" = azurerm_logic_app_workflow.event_notification.name }
    "storageConnectionName" = { "value" = azurerm_api_connection.storage.name }
    "queueName"        = { "value" = var.event_queue_name }
    "emailRecipient"   = { "value" = var.notification_email }
  })
  
  template_content = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "logicAppName": { "type": "string" },
    "storageConnectionName": { "type": "string" },
    "queueName": { "type": "string" },
    "emailRecipient": { "type": "string" }
  },
  "resources": [
    {
      "type": "Microsoft.Logic/workflows/providers/roleAssignments",
      "name": "[concat(parameters('logicAppName'), '/Microsoft.Authorization/', guid(parameters('logicAppName')))]",
      "apiVersion": "2020-04-01-preview",
      "properties": {
        "roleDefinitionId": "[concat('/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/', 'b24988ac-6180-42a0-ab88-20f7382dd24c')]",
        "principalId": "[reference(resourceId('Microsoft.Logic/workflows', parameters('logicAppName')), '2019-05-01', 'Full').identity.principalId]",
        "principalType": "ServicePrincipal"
      },
      "dependsOn": [
        "[resourceId('Microsoft.Logic/workflows', parameters('logicAppName'))]"
      ]
    },
    {
      "type": "Microsoft.Logic/workflows",
      "apiVersion": "2017-07-01",
      "name": "[parameters('logicAppName')]",
      "location": "${var.location}",
      "identity": {
        "type": "SystemAssigned"
      },
      "properties": {
        "state": "Enabled",
        "definition": {
          "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
          "contentVersion": "1.0.0.0",
          "parameters": {
            "$connections": {
              "defaultValue": {},
              "type": "Object"
            }
          },
          "triggers": {
            "When_there_are_messages_in_a_queue": {
              "recurrence": {
                "frequency": "Minute",
                "interval": 3
              },
              "splitOn": "@triggerBody().$values",
              "type": "ApiConnection",
              "inputs": {
                "host": {
                  "connection": {
                    "name": "@parameters('$connections')['azurequeues']['connectionId']"
                  }
                },
                "method": "get",
                "path": "/v2/storageAccounts/@{encodeURIComponent(encodeURIComponent('${data.azurerm_storage_account.existing.name}'))}/queues/@{encodeURIComponent('events-${var.unique_id}')}/messages",
                "queries": {
                  "peekOnly": false,
                  "queueMetadata": "none"
                }
              }
            }
          },
          "actions": {
            "Parse_JSON": {
              "runAfter": {},
              "type": "ParseJson",
              "inputs": {
                "content": "@{base64ToString(triggerBody()?['ContentData'])}",
                "schema": {
                  "properties": {
                    "message": {
                      "type": "string"
                    },
                    "subject": {
                      "type": "string"
                    },
                    "timestamp": {
                      "type": "string"
                    }
                  },
                  "type": "object"
                }
              }
            },
            "Send_an_email": {
              "runAfter": {
                "Parse_JSON": [
                  "Succeeded"
                ]
              },
              "type": "ApiConnection",
              "inputs": {
                "body": {
                  "Body": "<p>A new event was detected in your CANedge log processing pipeline:</p><p>@{body('Parse_JSON')['message']}</p><p>Event Time (UTC): @{body('Parse_JSON')['timestamp']}</p>",
                  "Subject": "CANedge Alert: @{body('Parse_JSON')['subject']}",
                  "To": "[parameters('emailRecipient')]"
                },
                "host": {
                  "connection": {
                    "name": "@parameters('$connections')['office365']"
                  }
                },
                "method": "post",
                "path": "/v2/Mail"
              }
            }
          },
          "outputs": {}
        },
        "parameters": {
          "$connections": {
            "value": {
              "azurequeues": {
                "connectionId": "[resourceId('Microsoft.Web/connections', parameters('storageConnectionName'))]",
                "connectionName": "[parameters('storageConnectionName')]",
                "id": "[concat('/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/azurequeues')]"
              },
              "office365": {
                "connectionId": "[resourceId('Microsoft.Web/connections', 'office365')]",
                "connectionName": "office365",
                "id": "[concat('/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/office365')]"
              }
            }
          }
        }
      }
    }
  ],
  "outputs": {}
}
TEMPLATE
  
  depends_on = [
    azurerm_logic_app_workflow.event_notification,
    azurerm_api_connection.storage
  ]
}

