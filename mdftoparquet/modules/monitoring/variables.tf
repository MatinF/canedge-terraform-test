variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources"
  type        = string
}

variable "location" {
  description = "The Azure region in which to create the resources"
  type        = string
}

variable "unique_id" {
  description = "Unique ID used for naming resources"
  type        = string
}

variable "notification_email" {
  description = "Email address to send notifications to"
  type        = string
}

variable "application_insights_id" {
  description = "The ID of the Application Insights instance to monitor"
  type        = string
}
