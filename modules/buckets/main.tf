/**
* Module to create the output bucket for Parquet files
*/

resource "google_storage_bucket" "output_bucket" {
  name     = "${var.input_bucket_name}-parquet"
  location = var.region
  
  uniform_bucket_level_access = true
  storage_class = "STANDARD"
  
  # Enable Hierarchical Namespace for the bucket
  hierarchical_namespace {
    enabled = true
  }
}
