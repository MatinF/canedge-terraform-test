/**
 * Output variables for Event Grid resources - only used in the second phase
 * This file should only be included when include_event_grid_subscription is true
 */

# We'll include this output file conditionally in the deployment script
output "eventgrid_subscription_name" {
  description = "Name of the Event Grid Subscription"
  value       = length(azurerm_eventgrid_system_topic_event_subscription.input_events) > 0 ? azurerm_eventgrid_system_topic_event_subscription.input_events[0].name : null
}
