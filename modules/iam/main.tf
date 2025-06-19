/**
* IAM module for creating service accounts and permissions
*/

# Create service account for the Cloud Function
resource "google_service_account" "function_service_account" {
  account_id   = "${var.unique_id}-function-sa"
  display_name = "CANedge Processor Function Service Account"
  description  = "Service account for the MDF4-to-Parquet Cloud Function"
}

# Grant the service account access to the input bucket
resource "google_storage_bucket_iam_member" "function_input_bucket_access" {
  bucket = var.input_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.function_service_account.email}"
}

# Grant the service account access to create objects in the output bucket
resource "google_storage_bucket_iam_member" "function_output_bucket_access" {
  bucket = var.output_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.function_service_account.email}"
}

# Grant additional roles for logging
resource "google_project_iam_member" "function_logging" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.function_service_account.email}"
}
