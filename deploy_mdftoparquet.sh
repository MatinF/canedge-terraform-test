#!/bin/bash
# CANedge GCP MDF4-to-Parquet Pipeline - One-Command Deployment Script

# Display help information
show_help() {
  echo "CANedge GCP MDF4-to-Parquet Pipeline - Automated Deployment"
  echo
  echo "Usage:"
  echo "  ./deploy_mdftoparquet.sh [options]"
  echo
  echo "Options:"
  echo "  -p, --project PROJECT_ID    GCP Project ID (REQUIRED)"
  echo "  -r, --region REGION         GCP region for deployment (auto-detected from bucket if not provided)"
  echo "  -b, --bucket BUCKET_NAME    Input bucket name (REQUIRED)"
  echo "  -i, --id UNIQUE_ID          Unique identifier (default: canedge-demo)"
  echo "  -y, --auto-approve          Skip approval prompt"
  echo "  -h, --help                  Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy_mdftoparquet.sh --project my-project-123 --region europe-west4 --bucket canedge-test-bucket-gcp"
}

# Default values
UNIQUE_ID="canedge-demo"
AUTO_APPROVE=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--project)
      PROJECT_ID="$2"
      shift 2
      ;;
    -r|--region)
      REGION="$2"
      shift 2
      ;;
    -b|--bucket)
      BUCKET_NAME="$2"
      shift 2
      ;;
    -i|--id)
      UNIQUE_ID="$2"
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

# Check if project ID is provided
if [ -z "$PROJECT_ID" ]; then
  echo "Error: Project ID is required. Please specify with --project flag."
  show_help
  exit 1
fi

# Check if bucket name is provided
if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Input bucket name is required. Please specify with --bucket flag."
  show_help
  exit 1
fi

# Check if the input bucket exists
echo "Checking input bucket..."
gsutil ls -b gs://${BUCKET_NAME} > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Input bucket '${BUCKET_NAME}' not found. Please create the bucket first before deploying."
  echo "   You can use ./deploy_input_bucket.sh to create the input bucket."
  exit 1
fi
echo "✓ Input bucket found."

# If region is not provided, auto-detect it from the bucket
if [ -z "$REGION" ]; then
  echo "Auto-detecting region from input bucket..."
  BUCKET_INFO=$(gsutil ls -L -b gs://${BUCKET_NAME})
  
  # Extract region from bucket info
  REGION=$(echo "$BUCKET_INFO" | grep -i "location constraint:" | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
  
  if [ -z "$REGION" ]; then
    echo "❌ Failed to auto-detect region from bucket. Please specify with --region flag."
    exit 1
  fi
  
  echo "✓ Detected region: $REGION"
fi

# Print deployment configuration
echo "🚀 Deploying CANedge GCP MDF4-to-Parquet Pipeline with the following configuration:"
echo "   - Project ID:    $PROJECT_ID"
echo "   - Region:        $REGION"
echo "   - Input Bucket:  $BUCKET_NAME"
echo "   - Unique ID:     $UNIQUE_ID"
echo

# Move to the mdftoparquet directory
cd mdftoparquet

# Initialize Terraform with backend config pointing to input bucket
echo "Initializing Terraform with state stored in input bucket..."
terraform init -reconfigure \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=terraform/state/mdftoparquet"

# Apply Terraform configuration with variables
echo "Applying Terraform configuration..."
terraform apply ${AUTO_APPROVE} \
  -var="project=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -var="input_bucket_name=${BUCKET_NAME}" \
  -var="unique_id=${UNIQUE_ID}"

# Show success message if deployment was successful
if [ $? -eq 0 ]; then
  echo
  echo "✅ Deployment successful!"
  echo
  echo "Next steps:"
  echo "1. Ensure your MDF4-to-Parquet function ZIP file is uploaded to: gs://${BUCKET_NAME}/mdf-to-parquet-google-function-v1.4.0.zip"
  echo "2. Upload an MDF4 file to your input bucket to test the function"
  echo "3. Check the output bucket for generated Parquet files: gs://${BUCKET_NAME}-parquet"
fi
