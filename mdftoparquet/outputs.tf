/**
* Outputs for the CANedge GCP Terraform Stack
*/

output "output_bucket_name" {
  description = "Name of the created output bucket for Parquet files"
  value       = module.output_bucket.output_bucket_name
}

output "cloud_function_name" {
  description = "Name of the deployed Cloud Function"
  value       = module.cloud_function.function_name
}

output "service_account_email" {
  description = "Service account email used by the Cloud Function"
  value       = module.iam.service_account_email
}

output "service_account_key" {
  description = "Service account key for local development (base64-encoded JSON)"
  value       = module.iam.service_account_key
  sensitive   = true
}

# Temporarily disabled for troubleshooting
# output "pubsub_topic_path" {
#   description = "Full resource path of the Pub/Sub topic for notifications"
#   value       = module.pubsub.topic_path
# }

# Monitoring outputs temporarily removed for troubleshooting
