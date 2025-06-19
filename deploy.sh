#!/bin/bash
# CANedge GCP Terraform Stack - One-Command Deployment Script

# Display help information
show_help() {
  echo "CANedge GCP Terraform Stack - Automated Deployment"
  echo
  echo "Usage:"
  echo "  ./deploy.sh [options]"
  echo
  echo "Options:"
  echo "  -p, --project PROJECT_ID    GCP Project ID (REQUIRED)"
  echo "  -r, --region REGION         GCP region for deployment (default: europe-west4)"
  echo "  -b, --bucket BUCKET_NAME    Input bucket name (default: canedge-test-bucket-gcp)"
  echo "  -i, --id UNIQUE_ID          Unique identifier (default: canedge-demo)"
  echo "  -y, --auto-approve          Skip approval prompt"
  echo "  -h, --help                  Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy.sh --region europe-west4 --bucket canedge-test-bucket-gcp"
}

# Default values
REGION="europe-west4"
BUCKET_NAME="canedge-test-bucket-gcp"
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

# Print deployment configuration
echo "🚀 Deploying CANedge GCP Terraform Stack with the following configuration:"
echo "   - Project ID:    $PROJECT_ID"
echo "   - Region:        $REGION"
echo "   - Input Bucket:  $BUCKET_NAME"
echo "   - Unique ID:     $UNIQUE_ID"
echo

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

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
  echo "1. Ensure your MDF4-to-Parquet function ZIP file is uploaded to: gs://${BUCKET_NAME}/mdf-to-parquet-google-function-v1.3.0.zip"
  echo "2. Upload an MDF4 file to your input bucket to test the function"
  echo "3. Check the output bucket for generated Parquet files: gs://${BUCKET_NAME}-parquet"
fi
