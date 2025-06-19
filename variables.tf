/**
* Input variables for the CANedge GCP Terraform Stack
*/

variable "project" {
  description = "GCP Project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment (e.g., europe-west4)"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the existing GCS bucket containing MDF4 files"
  type        = string
}

variable "unique_id" {
  description = "Unique identifier to namespace resources"
  type        = string
  default     = "canedge"
}
