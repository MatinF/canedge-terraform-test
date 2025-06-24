/**
* Variables for the BigQuery table mapping Cloud Run Job
*/

variable "project" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
}

variable "unique_id" {
  description = "A unique identifier for the deployment"
  type        = string
}

variable "input_bucket_name" {
  description = "Name of the bucket containing the job ZIP file"
  type        = string
}

variable "output_bucket_name" {
  description = "Name of the bucket containing the Parquet files"
  type        = string
}

variable "job_zip" {
  description = "Name of the ZIP file containing the job code"
  type        = string
  default     = "bigquery-map-tables-v1.0.0.zip"
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the job"
  type        = string
}

variable "iam_dependencies" {
  description = "Dependencies for IAM permissions to be applied before creating the job"
  type        = list(any)
  default     = []
}
