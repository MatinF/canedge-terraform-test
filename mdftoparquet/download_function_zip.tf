/**
* This file handles downloading the function ZIP file from Azure Storage to use with zip_deploy_file
* Allows users to update their function by uploading a new ZIP and referencing it by name
*/

# Generate a SAS URL for downloading the function ZIP
locals {
  function_zip_path = "${path.module}/function-deploy-package.zip"
  download_url = "https://${var.storage_account_name}.blob.core.windows.net/${var.input_container_name}/${var.function_zip_name}${data.azurerm_storage_account_sas.function_sas.sas}"
}

# Use null_resource to download the function ZIP from blob storage
resource "null_resource" "download_function_zip" {
  # This will force the download to happen on every apply
  triggers = {
    # Using the function ZIP name as a trigger ensures it runs when the zip name changes
    function_zip_name = var.function_zip_name
    # Additional timestamp trigger to force refresh on each apply
    timestamp = timestamp()
  }

  # Use curl to download the file (works in both Linux and Windows with Git Bash/WSL)
  provisioner "local-exec" {
    command = "curl -L -o ${local.function_zip_path} \"${local.download_url}\""
  }
}

# Output information about the downloaded function package
output "function_zip_details" {
  value = {
    name       = var.function_zip_name
    local_path = local.function_zip_path
    download_url = local.download_url
  }

  depends_on = [null_resource.download_function_zip]
  sensitive = true
}
