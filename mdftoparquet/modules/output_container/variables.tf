/**
* Variables for the output container module
*/

variable "output_container_name" {
  description = "Name of the output container for Parquet files"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account where the output container will be created"
  type        = string
}
