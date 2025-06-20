variable "project" {
  description = "GCP Project ID"
  type        = string
}

variable "unique_id" {
  description = "Unique identifier to prefix resource names"
  type        = string
}

variable "notification_email" {
  description = "Email address to receive notifications"
  type        = string
}
