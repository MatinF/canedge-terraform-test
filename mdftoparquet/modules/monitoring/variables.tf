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

variable "storage_account_name" {
  description = "The name of the storage account containing the event queue"
  type        = string
}

variable "event_queue_name" {
  description = "The name of the queue that will trigger the Logic App"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}
