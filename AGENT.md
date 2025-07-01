# Context
Read the README.md and the mdftoparquet/ folder and the deploy_mdftoparquet.sh in full.

Also read through the info/




# My current issue
I can deploy the input container stack without issues.

After this, I try to deploy the mdftoparquet stack, but I get an issue as below:

```
╷
│ Error: creating/updating System Topic Event Subscription (Subscription: "714b7bef-30a3-4e30-9b9f-7a1dcd5f7c7e"
│ Resource Group Name: "terraform-group-9"
│ System Topic Name: "evgt-newrepo2"
│ Event Subscription Name: "evgs-newrepo2"): polling after SystemTopicEventSubscriptionsCreateOrUpdate: polling failed: the Azure API returned the following error:
│ 
│ Status: "Failed"
│ Code: "Endpoint validation"
│ Message: "Destination endpoint not found. Resource details: resourceId: /subscriptions/714b7bef-30a3-4e30-9b9f-7a1dcd5f7c7e/resourceGroups/terraform-group-9/providers/Microsoft.Web/sites/mdftoparquet-newrepo2/functions/ProcessMdfToParquet. Resource should pre-exist before attempting this operation. Activity id:8394b188-d7d0-4145-b872-2a6a626ce385, timestamp: 6/30/2025 6:51:50 PM (UTC)."
│ Activity Id: ""
│ 
│ ---
│ 
│ API Response:
│ 
│ ----[start]----
│ {"id":"https://management.azure.com/subscriptions/714B7BEF-30A3-4E30-9B9F-7A1DCD5F7C7E/providers/Microsoft.EventGrid/locations/germanywestcentral/operationsStatus/F35CE068-A1E3-4A4B-AE3C-3C21EE954E18?api-version=2022-06-15","name":"f35ce068-a1e3-4a4b-ae3c-3c21ee954e18","status":"Failed","error":{"code":"Endpoint validation","message":"Destination endpoint not found. Resource details: resourceId: /subscriptions/714b7bef-30a3-4e30-9b9f-7a1dcd5f7c7e/resourceGroups/terraform-group-9/providers/Microsoft.Web/sites/mdftoparquet-newrepo2/functions/ProcessMdfToParquet. Resource should pre-exist before attempting this operation. Activity id:8394b188-d7d0-4145-b872-2a6a626ce385, timestamp: 6/30/2025 6:51:50 PM (UTC)."}}
│ -----[end]-----
│ 
│ 
│   with azurerm_eventgrid_system_topic_event_subscription.input_events,
│   on main.tf line 229, in resource "azurerm_eventgrid_system_topic_event_subscription" "input_events":
│  229: resource "azurerm_eventgrid_system_topic_event_subscription" "input_events" {
│ 
╵
❌  Deployment failed.
```

The problem is the inter-relation between the Azure Function and the Event Grid Subscription. This is not something that can be solved by simply adding a timeout in-between. 

Instead, please review the info/azure-functions-event-grid-terraform-main repository. This repository describes the type of issue I am facing and in the README.md and the examples it provides an example of how we can get around this issue.

# Task 1
Please review the relevant resources outlined. After this, propose a detailed plan on how to resolve the issue. Then implement the plan so that I can test if it solves the deployment issue.

