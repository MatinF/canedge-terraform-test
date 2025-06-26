/**
* Input variables for the CANedge Input Container Terraform Stack for Azure
*/

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name where resources will be deployed"
  type        = string
}

variable "storage_account_name" {
  description = "Azure Storage Account name for container deployment"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment (e.g., germanywestcentral)"
  type        = string
}

variable "container_name" {
  description = "Name of the storage container to be created"
  type        = string
}

variable "unique_id" {
  description = "Unique identifier to namespace resources"
  type        = string
  default     = "canedge"
}
