/**
* This file handles downloading the function ZIP file from Azure Storage to use with zip_deploy_file
* Allows users to update their function by uploading a new ZIP and referencing it by name
*/

# Create a local file resource to download the function ZIP from blob storage
resource "local_file" "function_zip" {
  filename = "${path.module}/function-deploy-package.zip"
  content_base64 = data.azurerm_storage_blob.function_zip.content_base64

  # This ensures the file is created before the function app tries to use it
  lifecycle {
    create_before_destroy = true
  }
}

# Fetch the function ZIP blob from storage
data "azurerm_storage_blob" "function_zip" {
  name                   = var.function_zip_name
  storage_account_name   = var.storage_account_name
  storage_container_name = var.input_container_name

  # This setting ensures Terraform always checks for changes to the blob
  # and will re-download it if it changes
  depends_on = [data.azurerm_storage_account_sas.function_sas]
}

# Output information about the downloaded function package
output "function_zip_details" {
  value = {
    name       = var.function_zip_name
    local_path = local_file.function_zip.filename
    content_md5 = data.azurerm_storage_blob.function_zip.content_md5
  }
}
