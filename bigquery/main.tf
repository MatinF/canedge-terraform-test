terraform {
  required_version = ">= 0.14.9"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    # These values are set by the terraform init command from deploy_bigquery.sh
    # bucket = "<input_bucket_name>"
    # prefix = "terraform/state/bigquery"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# BigQuery Dataset
module "dataset" {
  source     = "./modules/dataset"
  project    = var.project
  region     = var.region
  dataset_id = var.dataset_id
  unique_id  = var.unique_id
}

# Service Accounts
module "service_accounts" {
  source    = "./modules/service_accounts"
  project   = var.project
  unique_id = var.unique_id
}

# Output variables for use in scripts and documentation
output "project_id" {
  value = var.project
}

output "dataset_id" {
  value = module.dataset.dataset_id
}

output "bigquery_admin_service_account_email" {
  value = module.service_accounts.bigquery_admin_service_account_email
}

output "bigquery_user_service_account_email" {
  value = module.service_accounts.bigquery_user_service_account_email
}

output "bigquery_admin_key" {
  value     = module.service_accounts.bigquery_admin_key
  sensitive = true
}

output "bigquery_user_key" {
  value     = module.service_accounts.bigquery_user_key
  sensitive = true
}
