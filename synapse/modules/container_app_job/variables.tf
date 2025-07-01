variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "unique_id" {
  description = "Unique identifier to use in resource names"
  type        = string
}

variable "job_name" {
  description = "Name of the Container App Job"
  type        = string
  default     = "synapse-map-tables"
}

variable "container_image" {
  description = "Container image to use for the job"
  type        = string
  default     = "ghcr.io/css-electronics/canedge-synapse-map-tables:latest"
}

variable "storage_account_name" {
  description = "Name of the Azure Storage account"
  type        = string
}

variable "output_container_name" {
  description = "Name of the output container with Parquet files"
  type        = string
}

variable "synapse_server" {
  description = "Synapse SQL server endpoint"
  type        = string
}

variable "synapse_sql_password" {
  description = "Password for the Synapse SQL admin"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username for container registry authentication"
  type        = string
  default     = "MatinF"
}

variable "github_token" {
  description = "GitHub Personal Access Token with read:packages scope for container registry authentication"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU cores for the container"
  type        = string
  default     = "0.5"
}

variable "memory" {
  description = "Memory for the container in GB"
  type        = string
  default     = "1Gi"
}

variable "max_retry_count" {
  description = "Maximum number of retries for the job"
  type        = number
  default     = 1
}

variable "trigger_type" {
  description = "Trigger type for the job (Manual or Schedule)"
  type        = string
  default     = "Manual"
}

variable "database_name" {
  description = "The name of the database to be created in Synapse"
  type        = string
  default     = "canedge"
}
