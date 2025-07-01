#!/bin/bash

# Deployment script for Azure Synapse resources
# This script deploys Synapse resources for querying Parquet data in Azure

# Default values
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
STORAGE_ACCOUNT=""
INPUT_CONTAINER=""
UNIQUE_ID=""
DATABASE_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --subid)
      SUBSCRIPTION_ID="$2"
      shift
      shift
      ;;
    --resourcegroup)
      RESOURCE_GROUP="$2"
      shift
      shift
      ;;
    --storageaccount)
      STORAGE_ACCOUNT="$2"
      shift
      shift
      ;;
    --container)
      INPUT_CONTAINER="$2"
      shift
      shift
      ;;
    --id)
      UNIQUE_ID="$2"
      shift
      shift
      ;;

    --dataset)
      DATABASE_NAME="$2"
      shift
      shift
      ;;
    --github-token)
      GITHUB_TOKEN="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Check required parameters
if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Error: Subscription ID (--subid) is required"
  exit 1
fi

if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "Error: Resource group (--resourcegroup) is required"
  exit 1
fi

if [[ -z "$STORAGE_ACCOUNT" ]]; then
  echo "Error: Storage account (--storageaccount) is required"
  exit 1
fi

if [[ -z "$INPUT_CONTAINER" ]]; then
  echo "Error: Input container (--container) is required"
  exit 1
fi

if [[ -z "$UNIQUE_ID" ]]; then
  echo "Error: Unique ID (--id) is required"
  exit 1
fi

# Set the subscription context
echo "Setting Azure subscription context to $SUBSCRIPTION_ID..."
az account set --subscription "$SUBSCRIPTION_ID"

# Check if subscription exists
echo "Verifying subscription ID: $SUBSCRIPTION_ID..."
SUB_NAME=$(az account show --subscription "$SUBSCRIPTION_ID" --query "name" -o tsv 2>/dev/null)
if [ -z "$SUB_NAME" ]; then
  echo "Error: Subscription ID $SUBSCRIPTION_ID not found or not accessible"
  exit 1
else
  echo "Found subscription: $SUB_NAME"
fi

# Register the Microsoft.Synapse resource provider
echo "Registering the Microsoft.Synapse resource provider..."
az provider register --namespace Microsoft.Synapse
echo "Waiting for registration to complete (this may take a few minutes)..."
az provider show -n Microsoft.Synapse --query "registrationState"

# Wait for registration to complete
while [ "$(az provider show -n Microsoft.Synapse --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Still registering Microsoft.Synapse provider... (this can take several minutes)"
  sleep 10
done
echo "Microsoft.Synapse provider is now registered."

# Verify that the resource group exists
echo "Verifying resource group: $RESOURCE_GROUP"
RESGROUP_EXISTS=$(az group exists --name "$RESOURCE_GROUP")
if [ "$RESGROUP_EXISTS" != "true" ]; then
  echo "Error: Resource group '$RESOURCE_GROUP' does not exist in subscription '$SUBSCRIPTION_ID'."
  exit 1
fi

# Verify that the storage account exists
echo "Verifying storage account: $STORAGE_ACCOUNT"
STORAGE_EXISTS=$(az storage account check-name --name "$STORAGE_ACCOUNT" --query "nameAvailable" -o tsv)
if [ "$STORAGE_EXISTS" == "true" ]; then
  echo "Error: Storage account '$STORAGE_ACCOUNT' does not exist in resource group '$RESOURCE_GROUP'."
  exit 1
fi

# Verify that the input container exists
echo "Verifying input container: $INPUT_CONTAINER"
az storage container show --name "$INPUT_CONTAINER" --account-name "$STORAGE_ACCOUNT" --auth-mode login > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Input container $INPUT_CONTAINER does not exist in storage account $STORAGE_ACCOUNT"
  exit 1
fi
echo "Input container $INPUT_CONTAINER exists"

# Verify that the output container (created by MDF-to-Parquet) exists
OUTPUT_CONTAINER="${INPUT_CONTAINER}-parquet"
echo "Verifying output container: $OUTPUT_CONTAINER"
az storage container show --name "$OUTPUT_CONTAINER" --account-name "$STORAGE_ACCOUNT" --auth-mode login > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Error: Output container $OUTPUT_CONTAINER does not exist in storage account $STORAGE_ACCOUNT"
  echo "Make sure you've run the MDF-to-Parquet deployment first."
  exit 1
fi
echo "Output container $OUTPUT_CONTAINER exists"



if [[ -z "$DATABASE_NAME" ]]; then
  DATABASE_NAME="canedge"
  echo "Using default dataset name: $DATABASE_NAME"
fi

# Auto-detect the current user's email address using Azure CLI
echo "Detecting current user's email address..."
ADMIN_EMAIL=$(az ad signed-in-user show --query userPrincipalName -o tsv 2>/dev/null)

# Fallback in case direct email detection fails
if [ -z "$ADMIN_EMAIL" ]; then
  echo "Could not detect email directly, using account information..."
  OBJECT_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null)
  TENANT_ID=$(az account show --query tenantId -o tsv 2>/dev/null)
  ADMIN_EMAIL="$OBJECT_ID@$TENANT_ID"
  echo "Using generated admin identity: $ADMIN_EMAIL"
else
  echo "Detected user email: $ADMIN_EMAIL"
fi

echo "========================================================"
echo "Starting deployment with the following parameters:"
echo "  Subscription:    $SUBSCRIPTION_ID"
echo "  Resource Group:  $RESOURCE_GROUP"
echo "  Storage Account: $STORAGE_ACCOUNT"
echo "  Input Container: $INPUT_CONTAINER"
echo "  Unique ID:       $UNIQUE_ID"
echo "  Database Name:   $DATABASE_NAME"
echo "  Admin Email:     $ADMIN_EMAIL"
[[ -n "$GITHUB_TOKEN" ]] && echo "  GitHub Token:    Provided" || echo "  GitHub Token:    Not provided (public image required)"
echo "========================================================"

# Navigate to the synapse terraform directory
cd "$(dirname "$0")/synapse"

# Set up Terraform state storage in the input container
echo "Setting up Terraform state storage in the input container..."

# Initialize Terraform with remote state
echo "Initializing Terraform with remote state..."
terraform init \
  -backend-config="subscription_id=$SUBSCRIPTION_ID" \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$INPUT_CONTAINER" \
  -backend-config="key=terraform/state/synapse/default.tfstate"

# Create a terraform.tfvars file to avoid interactive prompts
echo "Creating terraform.tfvars file..."
cat > terraform.tfvars << EOF
subscription_id = "$SUBSCRIPTION_ID"
resource_group_name = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
input_container_name = "$INPUT_CONTAINER"
unique_id = "$UNIQUE_ID"
github_token = "$GITHUB_TOKEN"
database_name = "$DATABASE_NAME"
EOF

# Set environment variables for Terraform to use
export TF_VAR_subscription_id="$SUBSCRIPTION_ID"
export TF_VAR_resource_group_name="$RESOURCE_GROUP"
export TF_VAR_storage_account_name="$STORAGE_ACCOUNT"
export TF_VAR_input_container_name="$INPUT_CONTAINER"
export TF_VAR_unique_id="$UNIQUE_ID"
export TF_VAR_database_name="$DATABASE_NAME"
export TF_IN_AUTOMATION="true"  # This prevents interactive prompts

# Construct the Azure resource ID for the filesystem
STORAGE_ACCOUNT_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
FILESYSTEM_ID="$STORAGE_ACCOUNT_ID/blobServices/default/containers/${INPUT_CONTAINER}-parquet"

# Define our fixed state path
STATE_PATH="terraform/state/synapse/default.tfstate"
echo "Using state path: $STATE_PATH"

# Clean up local Terraform files
rm -rf .terraform .terraform.lock.hcl

# Simple Terraform initialization
echo "Initializing Terraform..."
terraform init \
  -backend-config="subscription_id=$SUBSCRIPTION_ID" \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$INPUT_CONTAINER" \
  -backend-config="key=$STATE_PATH"

# Apply the configuration
echo "Applying Terraform configuration..."  
terraform apply -auto-approve \
  -var "subscription_id=$SUBSCRIPTION_ID" \
  -var "resource_group_name=$RESOURCE_GROUP" \
  -var "storage_account_name=$STORAGE_ACCOUNT" \
  -var "input_container_name=$INPUT_CONTAINER" \
  -var "unique_id=$UNIQUE_ID" \
  -var "database_name=$DATABASE_NAME" \
  -var "admin_email=$ADMIN_EMAIL"

TERRAFORM_EXIT_CODE=$?

if [ $TERRAFORM_EXIT_CODE -ne 0 ]; then
  echo "Terraform apply failed."
  echo "Fix any errors above and try again."
  exit 1
else
  echo "Terraform apply succeeded!"
fi

# Function to show connection details
show_connection_details() {
  echo " "
  echo " "
  echo "======================================================="
  
  # Get the output and strip sensitive values markers
  terraform output -json synapse_connection_details 2>/dev/null | sed 's/"sensitive": true,//g' | jq -r '.'
  
  # Check if output was successful
  if [ $? -ne 0 ]; then
    echo "Failed to get connection details. This may indicate that the deployment was not successful."
    echo "Check the Azure portal to verify if the Synapse workspace was created."
    return 1
  fi
  return 0
}

# Function to show container app job information
show_job_information() {
  echo "======================================================="
  
  # Get the job instructions output
  terraform output -json synapse_table_mapper_instructions 2>/dev/null | jq -r '.'
  
  # Check if output was successful
  if [ $? -ne 0 ]; then
    echo "Failed to get Container App Job information."
    echo "Check the Azure portal to verify if the Container App Job was created."
    return 1
  fi
  return 0
}

# Only show connection details if deployment was successful
if [ $TERRAFORM_EXIT_CODE -eq 0 ]; then
  show_connection_details
  # Show Container App Job information
  show_job_information
  echo "======================================================="
  echo "Synapse deployment completed successfully"
  echo "======================================================="
  exit 0
else
  echo "======================================================="
  echo "Deployment had issues. Please check the output above for more details."
  echo "======================================================="
  exit $TERRAFORM_EXIT_CODE
fi
