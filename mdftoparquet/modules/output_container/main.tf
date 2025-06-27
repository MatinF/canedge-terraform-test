/**
* Output container module for the CANedge MDF-to-Parquet pipeline
* This creates the output container where Parquet files will be stored
*/

resource "azurerm_storage_container" "output_container" {
  name                  = var.output_container_name
  storage_account_id    = var.storage_account_id
  container_access_type = "private"
  
  # Prevent destruction of existing container
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      name,
      storage_account_id,
      container_access_type
    ]
  }
}
