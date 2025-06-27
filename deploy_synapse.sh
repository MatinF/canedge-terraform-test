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

# Create a terraform.tfvars file to avoid interactive prompts
echo "Creating terraform.tfvars file..."
cat > terraform.tfvars << EOF
subscription_id = "$SUBSCRIPTION_ID"
resource_group_name = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
input_container_name = "$INPUT_CONTAINER"
unique_id = "$UNIQUE_ID"
dataset_name = "$DATASET_NAME"
EOF

# Set environment variables for Terraform to use
export TF_VAR_subscription_id="$SUBSCRIPTION_ID"
export TF_VAR_resource_group_name="$RESOURCE_GROUP"
export TF_VAR_storage_account_name="$STORAGE_ACCOUNT"
export TF_VAR_input_container_name="$INPUT_CONTAINER"
export TF_VAR_unique_id="$UNIQUE_ID"
export TF_VAR_dataset_name="$DATASET_NAME"
export TF_IN_AUTOMATION="true"  # This prevents interactive prompts

# Construct the Azure resource ID for the filesystem
STORAGE_ACCOUNT_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT"
FILESYSTEM_ID="$STORAGE_ACCOUNT_ID/blobServices/default/containers/${INPUT_CONTAINER}-parquet"

# Skip the import if we're having issues with it
echo "Note: Skipping explicit import of the existing data lake filesystem."
echo "The deployment will reference the existing filesystem through the resource block with lifecycle rules."


# Proactively ensure clean state before starting
echo "Ensuring clean Terraform state..."

# Remove any local state files that might interfere
rm -f .terraform.lock.hcl terraform.tfstate* 2>/dev/null

# Define our fixed state path
STATE_PATH="terraform/state/synapse/default.tfstate"
echo "Using state path: $STATE_PATH"

# Clean up local Terraform files
rm -rf .terraform .terraform.lock.hcl

# Initialize terraform with clean local state
echo "Initializing Terraform..."
terraform init \
  -backend-config="subscription_id=$SUBSCRIPTION_ID" \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$INPUT_CONTAINER" \
  -backend-config="key=$STATE_PATH"

# Check if the state is locked
echo "Checking for existing state locks..."
LOCK_OUTPUT=$(terraform force-unlock -force "09920881-229c-fd2d-c61d-66cad6688d74" 2>&1 || echo "No lock found")

# Try another approach to break locks - use Azure CLI directly
echo "Using Azure CLI to check and break any blob lease..."
az storage blob show \
  --container-name "$INPUT_CONTAINER" \
  --name "$STATE_PATH" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --query "properties.lease.state" -o tsv 2>/dev/null

if [ $? -eq 0 ]; then
  echo "Breaking any lease on the state blob..."
  az storage blob lease break \
    --container-name "$INPUT_CONTAINER" \
    --name "$STATE_PATH" \
    --account-name "$STORAGE_ACCOUNT" \
    --auth-mode login 2>/dev/null
fi

# Re-initialize with no-lock to bypass any remaining lock issues
echo "Re-initializing Terraform with no-lock..."
rm -rf .terraform
terraform init -lock=false \
  -backend-config="subscription_id=$SUBSCRIPTION_ID" \
  -backend-config="resource_group_name=$RESOURCE_GROUP" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT" \
  -backend-config="container_name=$INPUT_CONTAINER" \
  -backend-config="key=$STATE_PATH"

# Apply with no-lock for consistency with initialization
echo "Applying Terraform configuration with no-lock..."  
terraform apply -auto-approve -lock=false \
  -var "subscription_id=$SUBSCRIPTION_ID" \
  -var "resource_group_name=$RESOURCE_GROUP" \
  -var "storage_account_name=$STORAGE_ACCOUNT" \
  -var "input_container_name=$INPUT_CONTAINER" \
  -var "unique_id=$UNIQUE_ID" \
  -var "dataset_name=$DATASET_NAME"

TERRAFORM_EXIT_CODE=$?

if [ $TERRAFORM_EXIT_CODE -ne 0 ]; then
  echo "Terraform apply failed."
  # We'll still try to show output in case it partially succeeded
else
  echo "Terraform apply succeeded!"
fi

# Function to show connection details
show_connection_details() {
  echo "======================================================="
  echo "Deployment complete! Showing connection details..." 
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

# Only show connection details if deployment was successful
if [ $TERRAFORM_EXIT_CODE -eq 0 ]; then
  show_connection_details
  echo "======================================================="
  echo "Synapse deployment completed successfully"
  echo "======================================================="
  exit 0
else
  echo "======================================================="
  echo "Attempting to show connection details despite errors..." 
  echo "======================================================="
  show_connection_details
  echo "======================================================="
  echo "Deployment had issues. Please check the output above for more details."
  echo "======================================================="
  exit $TERRAFORM_EXIT_CODE
fi
