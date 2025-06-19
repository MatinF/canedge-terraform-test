output "service_account_email" {
  description = "Email of the service account created for the Cloud Function"
  value       = google_service_account.function_service_account.email
}
