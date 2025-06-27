# Context
This repository contains terraform stacks and deployment scripts for deploying resources in Azure via the 'bash' cloud shell environment. See the README.md for details and go through all files in mdftoparquet/ as well as teh deploy_mdftoparquet.sh.

The mdftoparquet folder contains a deployment stack for deploying an Azure function. The user uploads a zip with the function contents into the input container. The deployment then fetches this and deploys it in an Azure Function App. It also deploys an output bucket.

The azure function code is stored in info/azure-function/

# Task 4
The current deployment works and correctly DBC decodes data via the function app.

We now wish to enable the user to receive a notification when an event happens in the data. You can see how this is handled in the Google Cloud case by looking at the google/mdftoparquet/ and in particular the google/mdftoparquet/modules/monitoring/ folder. Here, we use google's monitoring functionality to check if the info logs from the function invocation include a specific payload ("NEW EVENT"). If so, we consider this an event that triggers the deployed alert functionality and notifies the user by email.

We wish to implement a similar concept within Azure. As part of this, you've previously created a suggested plan for implementation. See the AGENT PLAN below for details.

Based on this plan (and the details above), please implement the solution.

Note: The monitoring/alerting terraform stack should be deployed in a modules/ folder called monitoring/ to match the structure of the other stack (we did some refactoring vs. previous deployments, so the AGENT PLAN below may be a bit outdated).

--------------

## AGENT PLAN

# Implementation Plan: Azure Function App Log Monitoring and Alerting

This document outlines the step-by-step plan for implementing Azure Monitor alerting for the MDF-to-Parquet Azure Function App. The goal is to enable email notifications when specific log patterns appear, similar to the approach used in the Google Cloud implementation.

## Overview

We'll leverage Azure Monitor and Application Insights to detect specific log patterns and send email alerts without requiring any third-party services or custom notification code. This will be done by:

1. Modifying the Azure Function code to emit specific log patterns for triggering alerts
2. Adding Azure Monitor resources to the Terraform stack to monitor these logs and send email alerts
3. Configuring the alerts to match the expected log patterns

## Step 1: Modify Azure Function Code

The function app code is stored in info/azure-function/.

Update the `modules/cloud_functions.py` file in the Azure Function App to emit specific log patterns that can trigger alerts:

1. Locate the `publish_notification` function in `cloud_functions.py`
2. Modify the Azure case to use a similar approach as the Google case:

```python
elif cloud == "Azure":
    logger.info(f"NEW EVENT: {message}")
    return True
```

This approach uses specific log patterns that Azure Monitor can detect, similar to how it works in the Google Cloud implementation.

## Step 2: Create Azure Monitor Resources in Terraform

Add the following resources to the `mdftoparquet` folder in an alert.tf file, which can then be referenced from within the main.tf file. Make sure the email address passed to this notification system is the one provided by the user as part of the deploy_mdftoparquet.sh step as an input.

1. Create an Azure Monitor Action Group for email notifications:

```hcl
# Action Group for sending email notifications
resource "azurerm_monitor_action_group" "email_alerts" {
  name                = "email-alerts-${var.unique_id}"
  resource_group_name = var.resource_group_name
  short_name          = "emailalrt"

  email_receiver {
    name                    = "admin"
    email_address           = var.email_address
    use_common_alert_schema = true
  }
}
```

2. Add a Log Alert Rule to detect the "NEW EVENT" pattern:

```hcl
# Alert rule for NEW EVENT log pattern
resource "azurerm_monitor_scheduled_query_rules_alert" "new_event_alert" {
  name                = "new-event-alert-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  action {
    action_group           = [azurerm_monitor_action_group.email_alerts.id]
    email_subject          = "CANedge Log Processing Event"
  }

  data_source_id = azurerm_application_insights.insights.id
  description    = "Alert when NEW EVENT is detected in function logs"
  enabled        = true

  # Query to detect the specific log pattern
  query       = <<-QUERY
  traces
  | where message contains "NEW EVENT"
  | project timestamp, message
  QUERY
  
  severity    = 1
  frequency   = 5  # Check every 5 minutes
  time_window = 10 # Look at the past 10 minutes
  
  # Trigger if any results are found
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
```

3. Also add a Log Alert Rule to detect any errors:

```hcl
# Alert rule for ERROR logs
resource "azurerm_monitor_scheduled_query_rules_alert" "error_alert" {
  name                = "error-alert-${var.unique_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  action {
    action_group           = [azurerm_monitor_action_group.email_alerts.id]
    email_subject          = "CANedge Log Processing Error"
  }

  data_source_id = azurerm_application_insights.insights.id
  description    = "Alert when errors are detected in function logs"
  enabled        = true

  # Query to detect error logs
  query       = <<-QUERY
  traces
  | where severityLevel == 3
  | project timestamp, message
  QUERY
  
  severity    = 1
  frequency   = 5  # Check every 5 minutes
  time_window = 10 # Look at the past 10 minutes
  
  # Trigger if any results are found
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }
}
```


Ensure the main.tf and deployment script is properly updated