/**
* Variables for the cloud function module
*/

variable "unique_id" {
  description = "Unique ID to use in resource names to ensure global uniqueness"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
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

variable "storage_account_id" {
  description = "Resource ID of the storage account"
  type        = string
}

variable "storage_account_access_key" {
  description = "Access key for the storage account"
  type        = string
  sensitive   = true
}

variable "storage_connection_string" {
  description = "Connection string for the storage account"
  type        = string
  sensitive   = true
}

variable "input_container_name" {
  description = "Name of the input container where MDF files are uploaded"
  type        = string
}

variable "output_container_name" {
  description = "Name of the output container for Parquet files"
  type        = string
}

variable "function_zip_name" {
  description = "Name of the MDF-to-Parquet function ZIP file in the input container"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Function App"
  type        = string
  default     = ""
}

variable "email_address" {
  description = "Email address for notifications"
  type        = string
}

variable "sas_token" {
  description = "SAS token for downloading the function ZIP"
  type        = string
  sensitive   = true
}
