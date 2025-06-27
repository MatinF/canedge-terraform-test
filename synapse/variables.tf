variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "storage_account_name" {
  description = "The storage account name that contains the data"
  type        = string
}

variable "input_container_name" {
  description = "The name of the input container"
  type        = string
}

variable "unique_id" {
  description = "A unique identifier for resources"
  type        = string
}

variable "dataset_name" {
  description = "The name of the dataset to be created in Synapse"
  type        = string
  default     = "canedge"
}
