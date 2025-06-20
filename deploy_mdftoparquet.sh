#!/bin/bash
# CANedge GCP MDF4-to-Parquet Pipeline - One-Command Deployment Script

# Display help information
show_help() {
  echo "CANedge MDF4-to-Parquet Pipeline - Automated Deployment"
  echo
  echo "Usage:"
  echo "  ./deploy_mdftoparquet.sh [options]"
  echo
  echo "Required:"
  echo "  -p, --project PROJECT_ID    GCP Project ID"
  echo "  -b, --bucket BUCKET_NAME    Input bucket name"
  echo
  echo "Optional:"
  echo "  -r, --region REGION         GCP region (auto-detected from bucket)"
  echo "  -i, --id UNIQUE_ID          Unique identifier (default: canedge-demo)"
  echo "  -y, --auto-approve          Skip approval prompt"
  echo "  -h, --help                  Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy_mdftoparquet.sh --project my-project-123 --bucket canedge-test-bucket-gcp --id my-pipeline"
}

# Default values
UNIQUE_ID="canedge-demo"
AUTO_APPROVE="-auto-approve" # Auto-approve by default

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

# Checking input bucket...
echo "Checking input bucket..."
gsutil ls -b "gs://${BUCKET_NAME}" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ ERROR: Input bucket '${BUCKET_NAME}' not found in project '${PROJECT_ID}'."
  echo "Please create the input bucket first using deploy_input_bucket.sh"
  exit 1
else
  echo "✓ Input bucket found."
fi

# Auto-detecting region from input bucket
echo "Auto-detecting region from input bucket..."
REGION=$(gsutil ls -L -b "gs://${BUCKET_NAME}" | grep -E "Location constraint:" | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
echo "✓ Detected region: ${REGION}"

# Check if output bucket already exists
OUTPUT_BUCKET_NAME="${BUCKET_NAME}-parquet"
echo "Checking if output bucket already exists..."
if gsutil ls -b "gs://${OUTPUT_BUCKET_NAME}" > /dev/null 2>&1; then
  echo "✓ Output bucket already exists, will be reused"
  BUCKET_EXISTS=true
else
  echo "✓ Output bucket will be created"
  BUCKET_EXISTS=false
fi

# Check if service account already exists or is in soft-delete state
SA_NAME="${UNIQUE_ID}-function-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "Checking if service account already exists..."

# First check if it's visible in the list of service accounts
if gcloud iam service-accounts list --project="$PROJECT_ID" --filter="email:${SA_EMAIL}" --format="value(email)" | grep -q "${SA_NAME}"; then
  echo "❌ ERROR: Service account '${SA_EMAIL}' already exists."
  echo "Please use a different --id parameter to avoid name conflicts."
  echo "Example: ./deploy_mdftoparquet.sh --project ${PROJECT_ID} --bucket ${BUCKET_NAME} --id ${UNIQUE_ID}-new"
  exit 1
fi

# Then check if it's in soft-delete state by trying to create it
TEMP_CHECK=$(gcloud iam service-accounts create "${SA_NAME}" --project="$PROJECT_ID" 2>&1 || true)
if [[ $TEMP_CHECK == *"already exists"* ]]; then
  echo "❌ ERROR: Service account '${SA_EMAIL}' appears to be in soft-delete state (30-day reservation period)."
  echo "Google Cloud reserves deleted service account names for approximately 30 days."
  echo "Please use a different --id parameter to avoid name conflicts."
  echo "Example: ./deploy_mdftoparquet.sh --project ${PROJECT_ID} --bucket ${BUCKET_NAME} --id ${UNIQUE_ID}-new"
  exit 1
else
  # If we were able to create it, delete it immediately as we'll let Terraform manage it
  if [[ $TEMP_CHECK != *"PERMISSION_DENIED"* ]]; then
    gcloud iam service-accounts delete "${SA_EMAIL}" --project="$PROJECT_ID" --quiet > /dev/null 2>&1 || true
  fi
  echo "✓ Service account name is available and will be created"
fi

# Check if cloud function already exists
FUNCTION_NAME="${UNIQUE_ID}-mdf-to-parquet"
echo "Checking if cloud function already exists..."
if gcloud functions describe "$FUNCTION_NAME" --gen2 --project="$PROJECT_ID" --region="$REGION" > /dev/null 2>&1; then
  echo "✓ Cloud function already exists, will be reused"
  FUNCTION_EXISTS=true
else
  echo "✓ Cloud function will be created"
  FUNCTION_EXISTS=false
fi

# Print deployment configuration
echo "Deploying MDF4-to-Parquet Pipeline:"
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
  -backend-config="prefix=terraform/state/mdftoparquet" > /dev/null

# Import existing resources if they exist
if [ "$BUCKET_EXISTS" = true ]; then
  echo "Importing existing output bucket into Terraform state..."
  echo "yes" | terraform import -var="project=${PROJECT_ID}" -var="region=${REGION}" \
    module.output_bucket.google_storage_bucket.output_bucket "${OUTPUT_BUCKET_NAME}" > /dev/null 2>&1 || true
fi

# No longer need to import service accounts as we'll exit if they already exist

# We've already checked for service account existence and exited if there were issues

if [ "$FUNCTION_EXISTS" = true ]; then
  echo "Importing existing cloud function into Terraform state..."
  echo "yes" | terraform import -var="project=${PROJECT_ID}" -var="region=${REGION}" \
    module.cloud_function.google_cloudfunctions2_function.mdf_to_parquet_function "projects/${PROJECT_ID}/locations/${REGION}/functions/${FUNCTION_NAME}" > /dev/null 2>&1 || true
fi

# Apply Terraform configuration with variables
echo "Applying Terraform configuration..."

# Run terraform apply with auto-approve
TERRAFORM_OUTPUT=$(terraform apply ${AUTO_APPROVE} \
  -var="project=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -var="input_bucket_name=${BUCKET_NAME}" \
  -var="unique_id=${UNIQUE_ID}")

# Check if the deployment was successful
if [ $? -eq 0 ]; then
  # Deployment successful, no cleanup needed
  # Extract important values from terraform output
  OUTPUT_BUCKET=$(terraform output -raw output_bucket_name 2>/dev/null)
  FUNCTION_NAME=$(terraform output -raw cloud_function_name 2>/dev/null)
  SERVICE_ACCOUNT=$(terraform output -raw service_account_email 2>/dev/null)
  
  # Get the service account key (base64-encoded JSON)
  SA_KEY=$(terraform output -raw service_account_key 2>/dev/null)
  
  # Decode the base64 key to get the JSON content
  SA_KEY_JSON=$(echo "${SA_KEY}" | base64 --decode)
  
  # Create a local file and upload it to the input bucket
  KEY_FILE="${UNIQUE_ID}-service-account-key.json"
  echo "${SA_KEY_JSON}" > ${KEY_FILE}
  
  # Upload to the input bucket
  echo "Uploading service account key to input bucket..."
  gsutil cp ${KEY_FILE} gs://${BUCKET_NAME}/${KEY_FILE}
  
  # Clean up the local file
  rm ${KEY_FILE}
  
  echo
  echo
  echo
  echo "---------------------------"
  echo "✅  Deployment successful!"
  echo
  echo "MDF4-to-Parquet details:"
  echo
  echo "Input bucket:           ${BUCKET_NAME}"
  echo "Output bucket:          ${OUTPUT_BUCKET}"
  echo "Function name:          ${FUNCTION_NAME}"
  echo "Service account:        ${SERVICE_ACCOUNT}"
  echo
  echo "Service account key saved to: gs://${BUCKET_NAME}/${KEY_FILE}"
  echo
  echo 
fi
