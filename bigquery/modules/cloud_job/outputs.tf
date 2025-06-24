/**
* Outputs for the BigQuery table mapping Cloud Run Job
*/

output "job_id" {
  description = "ID of the BigQuery table mapping Cloud Run Job"
  value       = google_cloud_run_v2_job.bigquery_map_tables_job.name
}

output "job_location" {
  description = "Location of the BigQuery table mapping Cloud Run Job"
  value       = google_cloud_run_v2_job.bigquery_map_tables_job.location
}

output "job_uri" {
  description = "Cloud Console URI for the BigQuery table mapping job"
  value       = "https://console.cloud.google.com/run/jobs/details/${google_cloud_run_v2_job.bigquery_map_tables_job.location}/${google_cloud_run_v2_job.bigquery_map_tables_job.name}?project=${var.project}"
}
