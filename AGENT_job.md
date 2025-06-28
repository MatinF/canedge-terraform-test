# Context
This repository contains terraform stacks and deployment scripts for deploying resources in Azure via the 'bash' cloud shell environment. See the README.md for details and go through all files in input_container/ + deploy_input_container.sh and and mdftoparquet/ + deploy_mdftoparquet.sh and synapse/ folder and deploy_synapse.sh to understand the deployment of initial resources.

I now want you to extend the synapse stack deployment with an Azure Container Apps Job. The goal is to host a basic Python script (with some requirements.txt dependencies) that will allow users via the Azure console to trigger the script periodically when they need. When the script is not actually running, there should be no cost to hosting it, i.e. the setup must be serverless (not e.g. a VM running all the time). 

The script will 'map tables' into our Azure Synapse workspace so as to allow us to map paths from our Parquet data lake stored in the output container (see the other deployments). Originally the script was designed to be run locally by the user where the user would hardcode data into the script with various authentication details and variables. Instead, we now want to deploy the script and parse all relevant information via environment variables so that the user does not have to do any manual modification. We've done some initial work at preparing the script for this.

The script is stored in info/synapse-map-tables-new. I'm not sure if the docker stuff I drafted makes sense, so feel free to remake this, as well as adjust the environment variable loading in the script. Note that the script relies on the dependencies from the requirements.txt to work.

Read through the script and files to understand the starting point.

# Task 1
Before you implement anything, make a JOB_PLAN.md where you note down the detailed steps on how you intend to deploy this task in practice. You should not add any new code or implement any changes beyond creating this plan to start with until I have had the chance to review and confirm the plan.

As part of the task, you need to add a new folder to synapse/modules and also update the synapse main.tf etc so as to deploy the azure job application. 

As part of this you must read through the documentation to ensure you make valid changes:
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job

We need to make it so that the Python script is updated to work with the environment variables and that we then enable it to be deployed thorugh the terraform stack. Update the deploy_synapse.sh to make the necessary deployment steps to deploy the job with the script and the dependencies installed. Note that the user will be doing this from the bash shell in Azure.

If the user has to upload a zip with some stuff related to this script into their input container, we can assume that they can do so and then provide the name of the zip via the input variables. But I do not know if this is the best route.

As part of the deployment outputs, provide brief guidance on how the user can run the job in Azure when there are updates to the device/message structure in their Parquet data lake. 

The expected end result (once you actually deploy after the plan stage) is a ready-to-use version of the script for mapping the Synapse tables, a bat file for compiling the script files into e.g. a zip (if that is relevant) or other end output and guidance on how it should be deployed. Further, I should be able to run the updated deployment script to deploy the necessary terraform stuff to deploy the job in Azure with the script and test that it runs as expected.

