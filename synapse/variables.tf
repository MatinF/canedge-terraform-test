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

variable "admin_email" {
  description = "The email address to be set as the SQL Microsoft Entra admin"
  type        = string
  default     = ""  # Will be dynamically determined if not provided
}

variable "github_token" {
  description = "GitHub Personal Access Token with read:packages scope for container registry authentication. THIS IS THE SINGLE SOURCE OF TRUTH FOR THE TOKEN - update only this value when the token changes."
  type        = string
  default     = "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"
  sensitive   = true
}
