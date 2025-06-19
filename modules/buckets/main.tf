/**
* Module to create the output bucket for Parquet files
*/

resource "google_storage_bucket" "output_bucket" {
  name     = "${var.input_bucket_name}-parquet"
  location = var.region
  
  uniform_bucket_level_access = true
  
  # Set reasonable defaults for storage
  storage_class = "STANDARD"
  
  # Optional: Configure lifecycle rules if needed
  lifecycle_rule {
    condition {
      age = 365  # Example: objects older than 1 year
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}
