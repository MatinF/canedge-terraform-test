/**
* Outputs for the cloud function module
*/

output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = azurerm_linux_function_app.function_app.name
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.function_app.default_hostname
}

output "function_app_id" {
  description = "Resource ID of the Function App"
  value       = azurerm_linux_function_app.function_app.id
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = azurerm_application_insights.insights.name
}

output "application_insights_id" {
  description = "Resource ID of the Application Insights instance"
  value       = azurerm_application_insights.insights.id
}

output "eventgrid_topic_name" {
  description = "Name of the Event Grid System Topic"
  value       = azurerm_eventgrid_system_topic.storage_events.name
}

output "eventgrid_subscription_name" {
  description = "Name of the Event Grid Subscription"
  value       = azurerm_eventgrid_system_topic_event_subscription.input_events.name
}
