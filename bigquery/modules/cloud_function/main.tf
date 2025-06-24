/**
* Module to deploy the Cloud Run Job for BigQuery table mapping
*/

# This forces Terraform to check the hash of the ZIP file at every apply
# and redeploy the job if the file has changed
data "external" "job_zip_hash" {
  program = ["bash", "-c", "echo '{\"result\":\"'$(gsutil hash gs://${var.input_bucket_name}/${var.function_zip} | grep md5 | awk '{print $3}')'\"}'"]
}

resource "google_cloud_run_v2_job" "bigquery_map_tables_job" {
  name        = "${var.unique_id}-bq-map-tables"
  project     = var.project
  location    = var.region
  description = "CANedge BigQuery table mapping job - Hash: ${data.external.job_zip_hash.result.result}"
  
  # Wait for IAM permissions to propagate before creating the job
  depends_on = [
    var.iam_dependencies
  ]

  template {
    template {
      containers {
        image = "us-docker.pkg.dev/cloudrun/container/job:latest" # Default container image
        
        # Source code from ZIP file
        command = ["/bin/bash", "-c", "pip install -r requirements.txt && python main.py"]
        
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
      
      volumes {
        name = "source-code"
        gcs {
          bucket = var.input_bucket_name
          object = var.function_zip
        }
      }
      
      service_account = var.service_account_email
      timeout = "3600s" # 60 minutes
    }
  }
  
  labels = {
    "goog-terraform-provisioned" = "true"
  }
}
