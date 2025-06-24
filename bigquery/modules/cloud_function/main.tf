/**
* Module to deploy the Cloud Function for BigQuery table mapping
*/

# This forces Terraform to check the hash of the ZIP file at every apply
# and redeploy the function if the file has changed
data "external" "function_zip_hash" {
  program = ["bash", "-c", "echo '{\"result\":\"'$(gsutil hash gs://${var.input_bucket_name}/${var.function_zip} | grep md5 | awk '{print $3}')'\"}'"]
}

resource "google_cloudfunctions2_function" "bigquery_map_tables_function" {
  name        = "${var.unique_id}-bq-map-tables"
  project     = var.project
  location    = var.region
  description = "CANedge BigQuery table mapping function - Hash: ${data.external.function_zip_hash.result.result}"
  
  # Wait for IAM permissions to propagate before creating the function
  depends_on = [
    var.iam_dependencies
  ]

  build_config {
    runtime     = "python311"
    entry_point = "map_bigquery_tables"
    source {
      storage_source {
        bucket = var.input_bucket_name
        object = var.function_zip
      }
    }
  }

  service_config {
    available_memory       = "1Gi"
    timeout_seconds        = 3600  # 60 minutes
    environment_variables  = {
      OUTPUT_BUCKET  = var.output_bucket_name
      DATASET_ID     = var.dataset_id
    }
    service_account_email  = var.service_account_email
    max_instance_count     = 1  # Limit to one instance to avoid race conditions
  }
  
  labels = {
    goog-terraform-provisioned = "true"
  }
}

# IAM binding for Cloud Functions v2 using the gcloud-based approach
# This uses the underlying Cloud Run service directly with the correct service name format

# Get the underlying Cloud Run service name directly from the function's output
# This is the reliable way to connect IAM permissions to Cloud Functions v2
# Use a data source to get current project details
data "google_project" "current" {
  project_id = var.project
}

# IAM binding to allow project owners to invoke the function
resource "google_cloud_run_service_iam_binding" "owner_invoker" {
  project  = var.project
  location = var.region
  service  = google_cloudfunctions2_function.bigquery_map_tables_function.name
  role     = "roles/run.invoker"
  members  = [
    "user:${data.google_project.current.creator_email}",  # Project creator is usually an owner
    # You can add more explicit owner email addresses here if needed
  ]
  
  # Important: Make sure the function is fully deployed before setting IAM
  depends_on = [
    google_cloudfunctions2_function.bigquery_map_tables_function
  ]
}
