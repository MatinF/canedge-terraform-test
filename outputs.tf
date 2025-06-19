/**
* Outputs for the CANedge GCP Terraform Stack
*/

output "output_bucket_name" {
  description = "Name of the created output bucket for Parquet files"
  value       = module.buckets.output_bucket_name
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

1. Upload the MDF4-to-Parquet function ZIP file to your input bucket:
   gs://${var.input_bucket_name}/mdf-to-parquet-google-function-v1.3.0.zip

2. Upload your DBC files to the input bucket (if needed)

3. To test, upload an MDF4 file to the input bucket and check the Cloud Function logs

4. Decoded Parquet files will appear in: gs://${module.buckets.output_bucket_name}
EOT
}
