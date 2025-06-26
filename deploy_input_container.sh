#!/bin/bash
# CANedge Azure Input Container - One-Command Deployment Script

# Display help information
show_help() {
  echo "CANedge Azure Input Container - Automated Deployment"
  echo
  echo "Usage:"
  echo "  ./deploy_input_container.sh [options]"
  echo
  echo "Options:"
  echo "  -g, --resourcegroup GROUP_NAME    Azure Resource Group name (REQUIRED)"
  echo "  -s, --storageaccount ACCOUNT_NAME Azure Storage Account name (REQUIRED)"
  echo "  -r, --region REGION               Azure region for deployment (e.g., germanywestcentral) (REQUIRED)"
  echo "  -c, --container CONTAINER_NAME    Input container name to create (REQUIRED)"
  echo "  -i, --subid SUBSCRIPTION_ID       Azure Subscription ID (OPTIONAL, default: current subscription)"
  echo "  -y, --auto-approve                Skip approval prompt"
  echo "  -h, --help                        Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy_input_container.sh --resourcegroup canedge-resources --storageaccount canedgestore --region germanywestcentral --container canedge-test-container"
}

# Default values
AUTO_APPROVE=""

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
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -c|--container)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    -i|--subid)
      USER_SUBSCRIPTION_ID="$2"
      shift 2
      ;;
    -y|--auto-approve)
      AUTO_APPROVE="-auto-approve"
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

if [ -z "$REGION" ]; then
  echo "Error: Region is required. Please specify with --region flag."
  show_help
  exit 1
fi

if [ -z "$CONTAINER_NAME" ]; then
  echo "Error: Container name is required. Please specify with --container flag."
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
  # Use the user-provided subscription ID
  SUBSCRIPTION_ID="$USER_SUBSCRIPTION_ID"
  echo "✓ Using specified subscription: $SUBSCRIPTION_ID"
fi

# Print deployment configuration
echo "Deploying CANedge Azure Input Container with the following configuration:"
echo "   - Resource Group:    $RESOURCE_GROUP_NAME"
echo "   - Storage Account:   $STORAGE_ACCOUNT_NAME"
echo "   - Region:            $REGION"
echo "   - Container Name:    $CONTAINER_NAME"
echo

# Move to the input_container directory
cd input_container

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply the Terraform configuration
echo "Applying Terraform configuration to create the input container..."

# Always auto-approve to avoid having to type "yes"
if [ -z "$AUTO_APPROVE" ]; then
  AUTO_APPROVE="-auto-approve"
fi

# Run terraform apply with all progress visible and don't hide outputs
terraform apply ${AUTO_APPROVE} \
  -var="subscription_id=${SUBSCRIPTION_ID}" \
  -var="resource_group_name=${RESOURCE_GROUP_NAME}" \
  -var="storage_account_name=${STORAGE_ACCOUNT_NAME}" \
  -var="location=${REGION}" \
  -var="container_name=${CONTAINER_NAME}"

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
echo "Resource Group:   $(echo $TERRAFORM_OUTPUT | jq -r '.resource_group_name.value')"
echo "Storage Account:  $(echo $TERRAFORM_OUTPUT | jq -r '.storage_account_name.value')"
echo "Container name:   $(echo $TERRAFORM_OUTPUT | jq -r '.container_name.value')"
echo "Region:           $(echo $TERRAFORM_OUTPUT | jq -r '.region.value')"
echo "SAS Token:        $(echo $TERRAFORM_OUTPUT | jq -r '.sas_token.value')"
echo
echo
