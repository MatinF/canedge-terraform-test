/**
* Module to deploy the Cloud Run Job for BigQuery table mapping
*/

# This forces Terraform to check the hash of the ZIP file at every apply
# and redeploy the job if the file has changed
data "external" "job_zip_hash" {
  program = ["bash", "-c", "echo '{\"result\":\"'$(gsutil hash gs://${var.input_bucket_name}/${var.job_zip} | grep md5 | awk '{print $3}')'\"}'"]
}

resource "google_cloud_run_v2_job" "bigquery_map_tables_job" {
  name        = "${var.unique_id}-bq-map-tables"
  project     = var.project
  location    = var.region
  launch_stage = "BETA"
  
  # Wait for IAM permissions to propagate before creating the job
  depends_on = [
    var.iam_dependencies
  ]

  template {
    task_count = 1
    template {
      max_retries = 0
      timeout = "3600s" # 60 minutes
      
      containers {
        image = "python:3.11-slim" # Python image that includes necessary tools
        
        # Source code from ZIP file
        command = ["/bin/bash"]
        args = ["-c", "apt-get update && apt-get install -y wget unzip && wget -O /tmp/code.zip https://storage.googleapis.com/${var.input_bucket_name}/${var.job_zip} && cd /tmp && unzip code.zip && pip install -r requirements.txt && python main.py"]
        
        resources {
          limits = {
            memory = "1Gi"
            cpu    = "1"
          }
        }
        
        env {
          name  = "OUTPUT_BUCKET"
          value = var.output_bucket_name
        }
        
        env {
          name  = "DATASET_ID"
          value = var.dataset_id
        }
      }
      
      service_account = var.service_account_email
    }
  }
  
  labels = {
    "goog-terraform-provisioned" = "true"
    "hash" = data.external.job_zip_hash.result.result
  }
}
