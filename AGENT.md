# Context
This repository contains a folder, google/. The folder contains a terraform deployment for Google Cloud.

The deployment is to be used by engineers that use the CANedge CAN bus data logger to collect raw CAN bus data (in MDF files aka MF4) and upload them to their own cloud server, in this case Google Cloud Platform. The terraform stack and deploy_input_bucket.sh enable users to easily deploy this via Google Cloud Shell once they are logged into Google Cloud with proper permissions. 


# Task 1
I now want you to create in the root of this repository a similar deployment, but this time for Azure. Specifically, this should enable users to follow the step-by-step guidance I provide in the README.md to deploy the container. As part of this, the users will need to provide information about what resource group and storage account to deploy it in. 

If the user specifies a resource group that does not yet exist, this should be created with default settings incl. the default subscription account. The resource group should be created with the region provided by the user and the name provided.

If the user specifies a storage account that does not yet exist, this should be created with default settings, though with 'Enable hierarchical namespace' enabled. 

If the user provides a resource group that already exists, the deployment should be done within this resource group.

If the user provides a storage account that already exists, the container deployment should be done within this storage account. 

Make sure to adjust the README.md if needed to match your implementation.

Create the necessary terraform stack resources by using the same style and folder structure as in the google/input_bucket/ folder, but named input_container in the root. And create a deployment script in the same style as the deploy_input_bucket.sh, but named deploy_input_container.sh

Start by creating a detailed implementation plan below. Once done, use this as reference while you create the resources. 

## DETAILED IMPLEMENTATION PLAN
[insert your detailed plan here]