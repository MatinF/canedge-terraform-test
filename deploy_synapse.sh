#!/bin/bash

# Deployment script for Azure Synapse resources
# This script deploys Synapse resources for querying Parquet data in Azure

# Default values
SUBSCRIPTION_ID=""
RESOURCE_GROUP=""
STORAGE_ACCOUNT=""
INPUT_CONTAINER=""
UNIQUE_ID=""
DATASET_NAME=""

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
      DATASET_NAME="$2"
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

# Set the Azure CLI to use the specified subscription
echo "Setting Azure CLI to use subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set Azure CLI to use subscription: $SUBSCRIPTION_ID"
  echo "Please make sure you are logged in to Azure CLI and the subscription ID is valid."
  exit 1
fi

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

# Verify that the container exists
echo "Verifying container: $INPUT_CONTAINER"
CONTAINER_EXISTS=$(az storage container exists --account-name "$STORAGE_ACCOUNT" --name "$INPUT_CONTAINER" --auth-mode login --query "exists" -o tsv)
if [ "$CONTAINER_EXISTS" != "true" ]; then
  echo "Error: Container '$INPUT_CONTAINER' does not exist in storage account '$STORAGE_ACCOUNT'."
  exit 1
fi

# Verify that the output container exists
echo "Verifying output container: ${INPUT_CONTAINER}-parquet"
OUTPUT_CONTAINER_EXISTS=$(az storage container exists --account-name "$STORAGE_ACCOUNT" --name "${INPUT_CONTAINER}-parquet" --auth-mode login --query "exists" -o tsv)
if [ "$OUTPUT_CONTAINER_EXISTS" != "true" ]; then
  echo "Error: Output container '${INPUT_CONTAINER}-parquet' does not exist. Make sure you've run the MDF-to-Parquet deployment first."
  exit 1
fi

if [[ -z "$DATASET_NAME" ]]; then
  DATASET_NAME="canedge"
  echo "Using default dataset name: $DATASET_NAME"
fi

echo "========================================================"
echo "Deploying Azure Synapse resources with the following parameters:"
echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Resource Group: $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Input Container: $INPUT_CONTAINER"
echo "Unique ID: $UNIQUE_ID"
echo "Dataset Name: $DATASET_NAME"
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

# Import the existing data lake filesystem resource
# Construct the Azure resource ID for the filesystem
STORAGE_ACCOUNT_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
FILESYSTEM_ID="$STORAGE_ACCOUNT_ID/blobServices/default/containers/${INPUT_CONTAINER}-parquet"

echo "Importing existing data lake filesystem: $FILESYSTEM_ID"
terraform import azurerm_storage_data_lake_gen2_filesystem.output "$FILESYSTEM_ID" || {
  echo "Warning: Could not import data lake filesystem. It may already be in the state file or might not exist."
  echo "Continuing with deployment..."
}

# Apply the Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve \
  -var "subscription_id=$SUBSCRIPTION_ID" \
  -var "resource_group_name=$RESOURCE_GROUP" \
  -var "storage_account_name=$STORAGE_ACCOUNT" \
  -var "input_container_name=$INPUT_CONTAINER" \
  -var "unique_id=$UNIQUE_ID" \
  -var "dataset_name=$DATASET_NAME"

# Show connection details
echo "========================================================"
echo "Deployment complete! Showing connection details..."
echo "========================================================"

# Get the output and strip sensitive values markers
terraform output -json synapse_connection_details | sed 's/"sensitive": true,//g' | jq -r '.'

echo "========================================================"
echo "Synapse deployment completed successfully"
echo "========================================================"
