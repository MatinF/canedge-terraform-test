#!/bin/bash

# Deploy MDF-to-Parquet pipeline on Azure
# This script deploys an Azure Function and related resources to convert MF4 files to Parquet format
# CSS Electronics ApS - www.csselectronics.com

# Function to show help text
show_help() {
  echo
  echo "CANedge MDF-to-Parquet Terraform Deployment for Azure"
  echo
  echo "Usage: ./deploy_mdftoparquet.sh [options]"
  echo
  echo "Options:"
  echo "  -g, --resourcegroup GROUP_NAME    Azure Resource Group name (REQUIRED)"
  echo "  -s, --storageaccount ACCOUNT_NAME Azure Storage Account name (REQUIRED)"
  echo "  -c, --container CONTAINER_NAME    Input container name (REQUIRED)"
  echo "  -i, --id UNIQUE_ID                Unique ID for resources (REQUIRED)"
  echo "  -e, --email EMAIL_ADDRESS         Email for notifications (REQUIRED)"
  echo "  -z, --zip FUNCTION_ZIP_NAME       Function ZIP filename in input container (REQUIRED)"
  # Output container is now automatically derived from input container name with '-parquet' suffix
  echo "  -f, --function FUNCTION_APP_NAME  Optional: custom function app name"
  echo "  -r, --region REGION               Azure region (default: same as storage account)"
  echo "  -subid SUBSCRIPTION_ID            Azure Subscription ID (optional, default: current subscription)"
  echo "  -y, --auto-approve                Skip approval prompt"
  echo "  -h, --help                        Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy_mdftoparquet.sh --resourcegroup canedge-resources --storageaccount canedgestore --container canedge-input --id datalake1 --email user@example.com --zip mdf-to-parquet-azure-function-v3.1.0.zip"
}

# Default values
AUTO_APPROVE="-auto-approve" # Auto-approve by default
OUTPUT_CONTAINER="parquet"
FUNCTION_APP_NAME=""
REGION=""

# Function to restart the Azure Function App after deployment
restart_function_app() {
  local function_app_name=$1
  local resource_group=$2
  
  echo "Restarting Azure Function App: $function_app_name..."
  az functionapp restart --name "$function_app_name" --resource-group "$resource_group"
  
  if [ $? -eq 0 ]; then
    echo "Function App restart successful."
  else
    echo "Warning: Function App restart failed. You may need to restart it manually from the Azure Portal."
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resourcegroup)
      RESOURCE_GROUP_NAME="$2"
      shift 2
      ;;
    -s|--storageaccount)
      STORAGE_ACCOUNT_NAME="$2"
      shift 2
      ;;
    -c|--container)
      INPUT_CONTAINER_NAME="$2"
      shift 2
      ;;
    -i|--id)
      UNIQUE_ID="$2"
      shift 2
      ;;
    -e|--email)
      EMAIL_ADDRESS="$2"
      shift 2
      ;;
    -z|--zip)
      FUNCTION_ZIP_NAME="$2"
      shift 2
      ;;
    # Output container parameter removed as it's now derived from input container name with '-parquet' suffix
    -f|--function)
      FUNCTION_APP_NAME="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -subid|--subid)
      USER_SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    -n|--no-auto-approve)
      AUTO_APPROVE="" # Disable auto-approve if flag is present
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check if required parameters are provided
if [ -z "$RESOURCE_GROUP_NAME" ]; then
  echo "Error: Resource Group name is required. Please specify with --resourcegroup flag."
  show_help
  exit 1
fi

if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
  echo "Error: Storage Account name is required. Please specify with --storageaccount flag."
  show_help
  exit 1
fi

if [ -z "$INPUT_CONTAINER_NAME" ]; then
  echo "Error: Input Container name is required. Please specify with --container flag."
  show_help
  exit 1
fi

if [ -z "$UNIQUE_ID" ]; then
  echo "Error: Unique ID is required. Please specify with --id flag."
  show_help
  exit 1
fi

if [ -z "$EMAIL_ADDRESS" ]; then
  echo "Error: Email address is required. Please specify with --email flag."
  show_help
  exit 1
fi

if [ -z "$FUNCTION_ZIP_NAME" ]; then
  echo "Error: Function ZIP name is required. Please specify with --zip flag."
  show_help
  exit 1
fi

# Verify Azure CLI installation and login status
echo "Verifying Azure CLI installation and authentication status..."
if ! command -v az &> /dev/null; then
  echo "❌ Azure CLI is not installed. Please install it first."
  echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
  exit 1
fi

# Check login status
ACCOUNT=$(az account show 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ You are not logged into Azure. Please login first with 'az login'."
  exit 1
fi

# Get subscription ID - use user-provided value if available, otherwise get from current account
if [ -z "$USER_SUBSCRIPTION_ID" ]; then
  # No user-provided subscription ID, get it from current account
  SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "❌ Could not determine subscription ID. Please verify your Azure account."
    exit 1
  fi
  echo "✓ Using default subscription: $SUBSCRIPTION_ID"
else
  # Use the user-provided subscription ID and set it as active
  SUBSCRIPTION_ID="$USER_SUBSCRIPTION_ID"
  echo "✓ Using specified subscription: $SUBSCRIPTION_ID"
  echo "Setting specified subscription as active..."
  az account set --subscription "$SUBSCRIPTION_ID"
  if [ $? -ne 0 ]; then
    echo "❌ Failed to set subscription. Verify the subscription ID is correct."
    exit 1
  fi
  echo "✓ Subscription set successfully"
fi

# Check if storage account exists and function zip file is in the container
echo "Verifying storage account and function ZIP file..."
STORAGE_ACCOUNT=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Storage Account '$STORAGE_ACCOUNT_NAME' not found in resource group '$RESOURCE_GROUP_NAME'."
  exit 1
fi

# Get storage account key
STORAGE_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "[0].value" -o tsv)
if [ -z "$STORAGE_KEY" ]; then
  echo "❌ Could not retrieve storage account key. Please verify your permissions."
  exit 1
fi

# Check if the input container exists
CONTAINER_EXISTS=$(az storage container exists --name "$INPUT_CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT_NAME" --auth-mode key --account-key "$STORAGE_KEY" --query "exists" -o tsv)
if [ "$CONTAINER_EXISTS" != "true" ]; then
  echo "❌ Input container '$INPUT_CONTAINER_NAME' does not exist in storage account '$STORAGE_ACCOUNT_NAME'."
  exit 1
fi

# New approach: No need to check if zip exists in blob storage since we're using the local path
echo "Using local function code from info/azure-function/updated-azure-function directory..."

# Create a fresh function-deploy-package.zip from the updated-azure-function directory
echo "Creating Function App deployment package..."
if [ -f "./mdftoparquet/function-deploy-package.zip" ]; then
    rm -f "./mdftoparquet/function-deploy-package.zip"
fi

# If region is not specified, get it from the storage account
if [ -z "$REGION" ]; then
  REGION=$(az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "location" -o tsv)
  echo "✓ Using region from storage account: $REGION"
fi

# Print deployment configuration
echo "\n----------------------------------------------"
echo "CANedge MDF-to-Parquet Deployment Configuration:"
echo "----------------------------------------------"
echo "Resource Group:     $RESOURCE_GROUP_NAME"
echo "Storage Account:    $STORAGE_ACCOUNT_NAME"
echo "Input Container:    $INPUT_CONTAINER_NAME"
echo "Output Container:   ${INPUT_CONTAINER_NAME}-parquet"
echo "Unique ID:          $UNIQUE_ID"
echo "Email Address:      $EMAIL_ADDRESS"
echo "Function ZIP:       [Using local source code]"
echo "Function App Name:  $FUNCTION_APP_NAME"
echo "Region:             $REGION"
echo "Subscription ID:    $SUBSCRIPTION_ID"
echo "Auto-Approve:       ${AUTO_APPROVE:1}"
echo "----------------------------------------------\n"

# Create terraform/state/mdftoparquet directory in input container
echo "Setting up Terraform state storage..."

# The state file itself will be created when Terraform initializes
# No need to create placeholder files as Azure Blob handles this automatically

# Initialize and apply Terraform
cd "$(dirname "$0")/mdftoparquet" || exit 1

echo "Initializing Terraform with remote state..."
terraform init \
  -backend-config="resource_group_name=$RESOURCE_GROUP_NAME" \
  -backend-config="storage_account_name=$STORAGE_ACCOUNT_NAME" \
  -backend-config="container_name=$INPUT_CONTAINER_NAME" \
  -backend-config="key=terraform/state/mdftoparquet/default.tfstate"

echo "Applying Terraform configuration to create the MDF-to-Parquet pipeline..."
terraform apply ${AUTO_APPROVE} \
  -var="subscription_id=${SUBSCRIPTION_ID}" \
  -var="resource_group_name=${RESOURCE_GROUP_NAME}" \
  -var="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
  -var="input_container_name=${INPUT_CONTAINER_NAME}" \
  -var="location=${REGION}" \
  -var="unique_id=${UNIQUE_ID}" \
  -var="email_address=${EMAIL_ADDRESS}" \
  -var="function_zip_name=${FUNCTION_ZIP_NAME}" \
  -var="function_app_name=${FUNCTION_APP_NAME}"

# Store exit code to check if deployment was successful
TF_EXIT_CODE=$?

# Get the outputs if the deployment was successful
if [ $TF_EXIT_CODE -eq 0 ]; then
  TERRAFORM_OUTPUT=$(terraform output -json)
  
  # Check if getting the outputs was successful
  if [ $? -ne 0 ]; then
    echo "❌  Failed to retrieve deployment outputs."
    exit 1
  fi
else
  echo "❌  Deployment failed."
  exit 1
fi

# Show the outputs
echo
echo
echo "---------------------------"
echo "✅  Deployment successful!"
echo
echo "Deployment details:"
echo
echo "Resource Group:       $(echo $TERRAFORM_OUTPUT | jq -r '.resource_group_name.value')"
echo "Storage Account:      $(echo $TERRAFORM_OUTPUT | jq -r '.storage_account_name.value')"
echo "Input Container:      $(echo $TERRAFORM_OUTPUT | jq -r '.input_container_name.value')"
echo "Output Container:     $(echo $TERRAFORM_OUTPUT | jq -r '.output_container_name.value')"
echo "Function App:         $(echo $TERRAFORM_OUTPUT | jq -r '.function_app_name.value')"
echo "Function App URL:     $(echo $TERRAFORM_OUTPUT | jq -r '.function_app_url.value')"
echo
echo "The MDF-to-Parquet pipeline has been successfully deployed!"
echo "Any MF4 files uploaded to the input container will be automatically processed to Parquet format and stored in the output container."
echo "Notifications will be sent to: $EMAIL_ADDRESS"
echo
echo "IMPORTANT: If using a non-Azure AD email address for notifications, you must verify it:"
echo "  1. Go to Azure Portal > Monitor > Action Groups"
echo "  2. Select 'email-alerts-$UNIQUE_ID'"
echo "  3. Check if email verification is needed (indicated by a warning icon)"
echo "  4. The recipient must verify the email address to receive alerts"
echo

# Restart the function app to ensure changes are recognized
FUNCTION_APP=$(echo $TERRAFORM_OUTPUT | jq -r '.function_app_name.value')
if [ ! -z "$FUNCTION_APP" ]; then
  restart_function_app "$FUNCTION_APP" "$RESOURCE_GROUP_NAME"
fi

echo
