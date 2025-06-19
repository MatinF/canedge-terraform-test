/**
* CANedge Input Bucket Creation on Google Cloud Platform
* Creates an input bucket with appropriate CORS settings for CANedge data
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84.0"
    }
  }
  
  # Store state in the input bucket once created
  # The actual bucket name is provided via -backend-config during terraform init
  backend "gcs" {
    prefix = "terraform/state/input_bucket"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Create the input bucket
resource "google_storage_bucket" "input_bucket" {
  name     = var.bucket_name
  location = var.region
  
  uniform_bucket_level_access = true
}

# Apply CORS settings to the input bucket
resource "google_storage_bucket_cors" "input_bucket_cors" {
  bucket = google_storage_bucket.input_bucket.name

  cors_rule {
    origin          = ["*"]
    method          = ["GET", "OPTIONS", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Create HMAC key for S3 interoperability
resource "google_storage_hmac_key" "key" {
  service_account_email = google_service_account.storage_admin.email
}

# Service account for HMAC key
resource "google_service_account" "storage_admin" {
  account_id   = "storage-admin-${var.unique_id}"
  display_name = "Storage Admin Service Account for ${var.unique_id}"
}

# Grant storage admin role to the service account
resource "google_project_iam_member" "storage_admin" {
  project = var.project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.storage_admin.email}"
}
