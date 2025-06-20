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

output "deployment_instructions" {
  description = "Next steps after deployment"
  value       = <<EOT
🎉 Deployment successful! Next steps:

1. Upload MDF4 files to your input bucket to test the function
2. Decoded Parquet files will appear in the output bucket
EOT
}
