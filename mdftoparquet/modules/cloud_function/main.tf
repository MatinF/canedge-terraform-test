/**
* Module to deploy the Cloud Function for MDF4-to-Parquet conversion
*/

# Get metadata about the zip file to detect changes
data "google_storage_object_metadata" "function_zip" {
  name   = "mdf-to-parquet-google-function-v1.7.0.zip"
  bucket = var.input_bucket_name
}

resource "google_cloudfunctions2_function" "mdf_to_parquet_function" {
  name        = "${var.unique_id}-mdf-to-parquet"
  project     = var.project
  location    = var.region
  description = "CANedge MDF4 to Parquet converter function"
  
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
  
  # This forces a redeploy whenever the content of the ZIP file changes
  # by adding metadata from the file (updated_time, md5hash) to the etag
  lifecycle {
    replace_triggered_by = [
      # This will trigger a redeploy if the file is changed or replaced
      data.google_storage_object_metadata.function_zip.md5_hash,
      data.google_storage_object_metadata.function_zip.time_created
    ]
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
