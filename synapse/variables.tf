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

variable "database_name" {
  description = "The name of the database to be created in Synapse"
  type        = string
  default     = "canedge"
}

variable "admin_email" {
  description = "The email address to be set as the SQL Microsoft Entra admin"
  type        = string
  default     = ""  # Will be dynamically determined if not provided
}

variable "github_token" {
  description = "GitHub Personal Access Token with read:packages scope for container registry authentication"
  type        = string
  sensitive   = true
}
