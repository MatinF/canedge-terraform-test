/**
* Module to deploy the Cloud Function for MDF4-to-Parquet conversion
*/

# Create the Cloud Function
resource "google_cloudfunctions_function" "mdf_to_parquet_function" {
  name        = "${var.unique_id}-mdf-to-parquet"
  description = "CANedge MDF4 to Parquet converter function"
  runtime     = "python311"
  region      = var.region

  # Source code comes from the input bucket
  source_archive_bucket = var.input_bucket_name
  source_archive_object = "mdf-to-parquet-google-function-v1.3.0.zip"
  entry_point           = "process_mdf_file"
  
  # Event trigger - runs when a new MDF4 file is uploaded
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = var.input_bucket_name
    failure_policy {
      retry = true
    }
    
    # Only trigger on MDF4 file extensions
    event_filters {
      attribute = "objectSuffix"
      value = ".MF4"
    }
  }
  
  # Additional event triggers for other supported file extensions
  dynamic "event_trigger" {
    for_each = [".MFC", ".MFE", ".MFM"]
    content {
      event_type = "google.storage.object.finalize"
      resource   = var.input_bucket_name
      
      # Only trigger on specified file extensions
      event_filters {
        attribute = "objectSuffix"
        value = event_trigger.value
      }
      
      failure_policy {
        retry = true
      }
    }
  }

  # Environment variables for the function
  environment_variables = {
    OUTPUT_BUCKET = var.output_bucket_name
  }

  # Use the service account created in the IAM module
  service_account_email = var.service_account_email
  
  # Allocate appropriate resources
  available_memory_mb   = 1024
  timeout               = 540  # 9 minutes max for Cloud Functions
}
