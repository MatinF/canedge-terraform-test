/**
* Module to deploy the Cloud Function for MDF4-to-Parquet conversion
*/

resource "google_cloudfunctions2_function" "mdf_to_parquet_function" {
  name     = "${var.unique_id}-mdf-to-parquet"
  project  = var.project
  location = var.region
  description = "CANedge MDF4 to Parquet converter function"

  build_config {
    runtime     = "python311"
    entry_point = "process_mdf_file"
    source {
      storage_source {
        bucket = var.input_bucket_name
        object = "mdf-to-parquet-google-function-v1.3.0.zip"
      }
    }
  }

  service_config {
    available_memory   = "1Gi"
    timeout_seconds    = 540
    environment_variables = {
      OUTPUT_BUCKET   = var.output_bucket_name
      FILE_EXTENSIONS = ".MF4,.MFC,.MFE,.MFM"
    }
    service_account_email = var.service_account_email
  }

  event_trigger {
    event_type    = "google.cloud.storage.object.v1.finalized"
    resource      = var.input_bucket_name
    trigger_region = var.region

    retry_policy = "RETRY_POLICY_RETRY"
  }

  labels = {
    goog-terraform-provisioned = "true"
  }
}

