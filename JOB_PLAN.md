# Azure Container App Job Deployment Plan

## Overview
This plan outlines the steps to extend the Synapse stack deployment with an Azure Container Apps Job that will run a Python script to map tables from Parquet data into the Azure Synapse workspace. The script will be deployed in a containerized, serverless environment that only incurs costs when the job is actually running.

## Current State Analysis
- The Python script (`synapse-map-tables.py`) is partially prepared to run with environment variables
- Basic Docker configuration (Dockerfile, entrypoint.sh) exists but may need improvements
- The script requires several dependencies (azure-functions, azure-storage-blob, pymssql, pyarrow)
- The script needs access to Azure Storage and Synapse SQL credentials

## Implementation Plan

### 1. Create New Terraform Module Structure
- Create a new folder `synapse/modules/container_app_job/` with:
  - `main.tf` - Main resource definitions
  - `variables.tf` - Input variables
  - `outputs.tf` - Output values
  - `versions.tf` - Provider versions

### 2. Container Registry and Image Preparation
**Option A: Azure Container Registry (ACR) + Build Task**
- Deploy an Azure Container Registry
- Set up CI/CD pipeline to build and push the container image
- Reference the image in the Container App Job

**Option B: Packaged Script Upload (preferred approach)**
- Create a ZIP packaging script (`package_job.sh`)
- Bundle the Python script, requirements.txt, and Dockerfile
- Upload to the input container during deployment
- Use ACI (Azure Container Instances) or Container App Jobs to build and deploy the image

### 3. Container App Job Resource Configuration
- Define the following Terraform resources:
  - `azurerm_container_app_environment` - Serverless environment
  - `azurerm_container_app_job` - The actual job definition
  - Supporting resources (Log Analytics workspace, Storage, etc.)

### 4. Python Script Enhancements
- Update the script to better handle environment variables with default values
- Add error handling and better logging
- Add command-line parameters for optional overrides
- Ensure compatibility with the Container App Job environment

### 5. Environment Variables Configuration
Configure the following environment variables:
- `STORAGE_ACCOUNT` - Storage account name
- `CONTAINER_OUTPUT` - Output container name with Parquet files
- `STORAGE_CONNECTION_STRING` - Connection string for Azure Storage
- `SYNAPSE_SERVER` - Synapse SQL endpoint
- `SYNAPSE_PASSWORD` - SQL admin password (from Terraform output)
- `MASTER_KEY_PASSWORD` - Password for the database master key
- `SYNAPSE_DATABASE` - Database name (with default)
- `SYNAPSE_USER` - SQL username (with default)

### 6. Integration with Synapse Module
- Update `synapse/main.tf` to:
  - Call the new container_app_job module
  - Pass necessary parameters from Synapse outputs (server, credentials)
  - Configure environment variables for the job

### 7. Deployment Script Updates
- Modify `deploy_synapse.sh` to:
  - Add parameter handling for any new variables
  - Package and upload the job code if using Option B
  - Handle Container App Job deployment as part of the Synapse deployment
  - Provide detailed output with connection info and job execution instructions

### 8. Security Considerations
- Use managed identities for authentication where possible
- Securely handle secrets through Key Vault or environment variables
- Grant minimal required permissions to the Container App Job

### 9. User Guidance Documentation
- Update outputs to include:
  - How to run the job through Azure Portal or Azure CLI
  - When to run the job (e.g., after data structure changes)
  - Troubleshooting common issues
  - How to view job logs

## Required Variables
- All existing variables from the Synapse module
- New variables:
  - `enable_container_job` (boolean, default: true) - Option to enable/disable job deployment
  - `job_name` (string, optional) - Custom name for the job
  - `job_schedule` (string, optional) - CRON schedule if automatic execution is desired

## Output Documentation
Output will include:
- Container App Job URL/ID
- Commands to manually trigger the job
- Instructions for when/why to run the job
- Links to monitoring resources

## Testing Plan
1. Deploy the updated stack with `deploy_synapse.sh`
2. Verify Container App Job deployment in Azure Portal
3. Test manual execution of the job
4. Verify table creation in Synapse

## Considerations and Risks
- Container App Job is relatively new in Azure; documentation and features may change
- Python dependencies might require specific versions for compatibility
- Job execution time limits should be evaluated based on data volume
- Regional availability of Container App services should be verified

---

This plan will be refined based on feedback before implementation begins.
