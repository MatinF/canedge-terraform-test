/**
* Module to deploy the Cloud Function for MDF4-to-Parquet conversion
*/

# This forces Terraform to check the hash of the ZIP file at every apply
# and redeploy the function if the file has changed
data "external" "function_zip_hash" {
  program = ["bash", "-c", "echo '{\"result\":\"'$(gsutil hash gs://${var.input_bucket_name}/mdf-to-parquet-google-function-v1.7.0.zip | grep md5 | awk '{print $3}')'\"}'"]
}

resource "google_cloudfunctions2_function" "mdf_to_parquet_function" {
  name        = "${var.unique_id}-mdf-to-parquet"
  project     = var.project
  location    = var.region
  description = "CANedge MDF4 to Parquet converter function - Hash: ${data.external.function_zip_hash.result.result}"
  
  # Wait for IAM permissions to propagate before creating the function
  depends_on = [
    var.iam_dependencies
  ]

  build_config {
    runtime     = "python311"
    entry_point = "process_mdf_file"
    source {
      storage_source {
        bucket = var.input_bucket_name
        object = "mdf-to-parquet-google-function-v1.7.0.zip"
      }
    }
  }

  service_config {
    available_memory       = "1Gi"
    timeout_seconds        = 150
    environment_variables  = {
      OUTPUT_BUCKET   = var.output_bucket_name
      FILE_EXTENSIONS = ".MF4,.MFC,.MFE,.MFM"
      PUBSUB_TOPIC    = var.pubsub_topic_path
    }
    service_account_email  = var.service_account_email
  }
  
  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_RETRY"
    service_account_email = var.service_account_email
    event_filters {
      attribute = "bucket"
      value     = var.input_bucket_name
    }
  }

  labels = {
    goog-terraform-provisioned = "true"
  }
}
