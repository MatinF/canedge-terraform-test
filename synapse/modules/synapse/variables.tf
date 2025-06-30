variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "unique_id" {
  description = "A unique identifier for resources"
  type        = string
}

variable "storage_account_name" {
  description = "The storage account name that contains the data"
  type        = string
}

variable "storage_data_lake_gen2_filesystem_id" {
  description = "The ID of the Data Lake Gen2 filesystem in the storage account (output container)"
  type        = string
}

variable "database_name" {
  description = "The name of the database to be created in Synapse"
  type        = string
}

variable "tenant_id" {
  description = "The Azure AD tenant ID for the Synapse admin"
  type        = string
}

variable "current_user_object_id" {
  description = "The object ID of the current user to be set as Synapse admin"
  type        = string
}

variable "admin_email" {
  description = "The email address to be set as the SQL Microsoft Entra admin"
  type        = string
}

variable "output_container_name" {
  description = "The name of the container where parquet files are stored"
  type        = string
}
