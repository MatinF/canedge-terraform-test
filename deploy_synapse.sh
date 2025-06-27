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

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

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
