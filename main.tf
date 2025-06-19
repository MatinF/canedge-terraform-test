/**
* CANedge MDF4-to-Parquet Pipeline on Google Cloud Platform
* Root module that calls all child modules
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google     = { source = "hashicorp/google",     version = ">= 6.0.0" }
    google-beta = { source = "hashicorp/google-beta", version = ">= 6.0.0" }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Create output bucket module
module "buckets" {
  source = "./modules/buckets"

  project          = var.project
  region           = var.region
  input_bucket_name = var.input_bucket_name
  unique_id        = var.unique_id
}

# IAM service account and permissions
module "iam" {
  source = "./modules/iam"

  project          = var.project
  unique_id        = var.unique_id
  input_bucket_name = var.input_bucket_name
  output_bucket_name = module.buckets.output_bucket_name
}

# Cloud Function for MDF4 to Parquet conversion
module "cloud_function" {
  source = "./modules/cloud_function"

  project              = var.project
  region               = var.region
  unique_id            = var.unique_id
  input_bucket_name    = var.input_bucket_name
  output_bucket_name   = module.buckets.output_bucket_name
  service_account_email = module.iam.service_account_email
}
