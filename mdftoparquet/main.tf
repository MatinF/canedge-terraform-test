/**
* CANedge MDF4-to-Parquet Pipeline on Google Cloud Platform
* Root module that calls all child modules
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84.0"
    }
  }
  
  # Store state in input bucket
  # The actual bucket name is provided via -backend-config during terraform init
  backend "gcs" {
    prefix = "terraform/state/mdftoparquet"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Create output bucket module
module "output_bucket" {
  source = "./modules/output_bucket"

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
  output_bucket_name = module.output_bucket.output_bucket_name
}

# Temporarily disabled Pub/Sub Topic for troubleshooting
# module "pubsub" {
#   source = "./modules/pubsub"
#
#   project           = var.project
#   unique_id         = var.unique_id
#   notification_email = var.notification_email
# }

# Cloud Function for MDF4 to Parquet conversion
module "cloud_function" {
  source = "./modules/cloud_function"

  project              = var.project
  region               = var.region
  unique_id            = var.unique_id
  input_bucket_name    = var.input_bucket_name
  output_bucket_name   = module.output_bucket.output_bucket_name
  service_account_email = module.iam.service_account_email
  pubsub_topic_path    = "" # Temporarily disabled PubSub
  function_zip         = var.function_zip
  
  # Pass explicit dependencies to ensure IAM permissions are fully applied before function creation
  iam_dependencies = [
    module.iam.service_account_email,
    module.iam.function_event_receiver_id, 
    module.iam.function_service_usage_id
  ]
}

# Monitoring module temporarily removed for troubleshooting
