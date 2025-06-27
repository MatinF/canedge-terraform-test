/**
* Input variables for the CANedge MDF-to-Parquet Terraform Stack for Azure
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
  description = "Azure Storage Account name containing the input container"
  type        = string
}

variable "input_container_name" {
  description = "Name of the input container where MDF files are uploaded"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "unique_id" {
  description = "Unique ID to use in resource names to ensure global uniqueness"
  type        = string
}

variable "email_address" {
  description = "Email address for notifications"
  type        = string
}

variable "function_zip_name" {
  description = "Name of the MDF-to-Parquet function ZIP file in the input container"
  type        = string
}

# Output container name is now derived from input container name with '-parquet' suffix

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
  default     = ""
}
