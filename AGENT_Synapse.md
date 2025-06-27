# Context
This repository contains terraform stacks and deployment scripts for deploying resources in Azure via the 'bash' cloud shell environment. See the README.md for details and go through all files in input_container/ + deploy_input_container.sh and and mdftoparquet/ + deploy_mdftoparquet.sh to understand the deployment of initial resources.

We now wish to also deploy Azure Synapse resources so that we can query the Parquet data lake stored in our output container. The steps that should be taken by the user to deploy this are described in the README.md.

## Task 1: Deploy Synapse resources

The Synapse deployment should consist of the following:

1) Create a new Synapse workspace (within the subscription and resource group provided by the user). Name it using the UNIQUE_ID provided as input by the user

2) The Synapse workspace Account name should reference the storage account provided by the user

3) The Synapse workspace File system name should reference the output container deployed (containing the Parquet files)

4) In security settings, a strong SQL password should be auto-generated and provided to the user as part of the console output (for noting down)

The output of the deployment should include the below (useful for when the user is going to interface with the Synapse deployment):

The following details can be used for connecting to the Synapse deployment: 

Name: Microsoft SQL Server
Host: Serverless SQL endpoint
Database: <YOUR_DATASET_NAME>
Authentication: SQL Server Authentication
User: sqladminuser
Password: <the generated SQL password in raw form>
Min time interval: 1ms
