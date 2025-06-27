/**
* This file adds a post-deployment step to restart the function app
* This ensures that any cached code is cleared and the new deployment is used
*/

# Use a null_resource to restart the function after deployment
resource "null_resource" "restart_function_app" {
  # This will force the restart to happen on every apply
  triggers = {
    deployment_id = random_uuid.deployment_id.result
    function_zip_name = var.function_zip_name
    timestamp = timestamp()
  }

  # Run az CLI command to restart the function app
  provisioner "local-exec" {
    command = "az functionapp restart --name ${azurerm_linux_function_app.function_app.name} --resource-group ${var.resource_group_name}"
  }

  depends_on = [
    azurerm_linux_function_app.function_app,
    null_resource.download_function_zip
  ]
}
