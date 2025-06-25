#!/bin/bash
# CANedge GCP MDF4-to-Parquet Pipeline - IAM and APIs Setup Script

# Check if the script is being executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Check if script has execute permissions (skip on Windows where chmod doesn't apply)
  if [[ "$(uname -s)" != CYGWIN* ]] && [[ "$(uname -s)" != MINGW* ]] && [[ "$(uname -s)" != MSYS* ]]; then
    if [[ ! -x "${BASH_SOURCE[0]}" ]]; then
      echo -e "\033[1;31mERROR: Permission denied\033[0m"
      echo "This script is not executable. Run the following command first:"
      script_name=$(basename "${BASH_SOURCE[0]}")
      echo "  chmod +x ${script_name}"
      exit 1
    fi
  fi
fi

# Display help information
show_help() {
  echo "CANedge MDF4-to-Parquet Pipeline - IAM and APIs Setup"
  echo
  echo "Usage:"
  echo "  ./deploy_mdftoparquet_1.sh [options]"
  echo
  echo "Required:"
  echo "  -p, --project PROJECT_ID    GCP Project ID"
  echo "  -b, --bucket BUCKET_NAME    Input bucket name"
  echo "  -i, --id UNIQUE_ID          Unique identifier for pipeline resources"
  echo "  -z, --zip FUNCTION_ZIP      Cloud Function ZIP filename (e.g. mdf-to-parquet-google-function-vX.X.X.zip)"
  echo
  echo "Optional:"
  echo "  -e, --email EMAIL           Email address to receive notifications"
  echo "  -y, --auto-approve          Skip approval prompt"
  echo "  -h, --help                  Show this help message"
  echo
  echo "Example:"
  echo "  ./deploy_mdftoparquet_1.sh --project my-project-123 --bucket canedge-test-bucket-gcp --id canedge-demo --email user@example.com --zip mdf-to-parquet-google-function-vX.X.X.zip"
}

# Default values
AUTO_APPROVE="-auto-approve" # Auto-approve by default
NOTIFICATION_EMAIL=""         # Email for notifications
# No default for UNIQUE_ID or FUNCTION_ZIP - user must provide them

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
    -e|--email)
      NOTIFICATION_EMAIL="$2"
      shift 2
      ;;
    -z|--zip)
      FUNCTION_ZIP="$2"
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

# Automatically configure the current project
echo "Setting project to '$PROJECT_ID'..."
gcloud config set project "$PROJECT_ID"
echo "✓ Project set to '$PROJECT_ID'."

# Check authentication status
echo "Checking GCP authentication status..."
AUTH_CHECK=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1)
if [[ -z "$AUTH_CHECK" ]]; then
  echo "❌ ERROR: Not authenticated with GCP. Please run 'gcloud auth login' first."
  exit 1
fi
echo "✓ Authenticated as $AUTH_CHECK"

# Enable required APIs
echo "Enabling required GCP APIs..."
echo "- Enabling Cloud Resource Manager API..."
gcloud services enable cloudresourcemanager.googleapis.com --quiet
echo "- Enabling IAM API..."
gcloud services enable iam.googleapis.com --quiet
echo "- Enabling Cloud Functions API..."
gcloud services enable cloudfunctions.googleapis.com --quiet
echo "- Enabling Cloud Run API..."
gcloud services enable run.googleapis.com --quiet
echo "- Enabling Cloud Build API..."
gcloud services enable cloudbuild.googleapis.com --quiet
echo "- Enabling Eventarc API..."
gcloud services enable eventarc.googleapis.com --quiet
echo "✓ All required APIs have been enabled."

# Ensure Eventarc service agent has proper permissions
echo "Setting up Eventarc service agent permissions..."
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com" \
  --role="roles/eventarc.serviceAgent" --quiet
echo "✓ Eventarc service agent permissions set."
echo "Waiting 20 seconds for permissions to propagate..."
sleep 20

# Check if bucket name is provided
if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Input bucket name is required. Please specify with --bucket flag."
  show_help
  exit 1
fi

# Checking input bucket...
echo "Checking input bucket..."
gsutil ls -b "gs://${BUCKET_NAME}" 2>&1
BUCKET_CHECK_RESULT=$?
if [ $BUCKET_CHECK_RESULT -ne 0 ]; then
  echo "❌ ERROR: Input bucket '${BUCKET_NAME}' not found in project '${PROJECT_ID}'."
  echo "Please create the input bucket first using deploy_input_bucket.sh"
  exit 1
else
  echo "✓ Input bucket found."
fi

# Check if unique ID is provided
if [ -z "$UNIQUE_ID" ]; then
  echo "Error: Unique ID is required. Please specify with --id flag."
  show_help
  exit 1
fi

# Check if function ZIP is provided
if [ -z "$FUNCTION_ZIP" ]; then
  echo "Error: Function ZIP filename is required. Please specify with --zip flag."
  show_help
  exit 1
fi

# Auto-detecting region from input bucket
echo "Auto-detecting region from input bucket..."
REGION=$(gsutil ls -L -b "gs://${BUCKET_NAME}" | grep -E "Location constraint:" | awk '{print $3}' | tr '[:upper:]' '[:lower:]')
echo "✓ Detected region: ${REGION}"

# Check if service account already exists
SA_NAME="${UNIQUE_ID}-function-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "Checking if service account already exists..."

# Check if service account is visible in the list
if gcloud iam service-accounts list --project="$PROJECT_ID" --filter="email:${SA_EMAIL}" --format="value(email)" | grep -q "${SA_NAME}"; then
  echo "✓ Service account already exists, will be reused"
  SA_EXISTS=true
else
  # Check if service account is in soft-delete state
  TEMP_CHECK=$(gcloud iam service-accounts create "${SA_NAME}-probe" --project="$PROJECT_ID" 2>&1 || true)
  if [[ $TEMP_CHECK == *"already exists"* ]]; then
    echo "✓ Service account appears to be in soft-delete state"
    echo "✓ Will create new service account with ID ${UNIQUE_ID}-function-sa"
    SA_EXISTS=false
  else
    # If we were able to create the probe account, delete it immediately 
    if [[ $TEMP_CHECK != *"PERMISSION_DENIED"* ]]; then
      gcloud iam service-accounts delete "${SA_NAME}-probe@${PROJECT_ID}.iam.gserviceaccount.com" --project="$PROJECT_ID" --quiet || true
    fi
    echo "✓ Service account will be created"
    SA_EXISTS=false
  fi
fi

# If notification email wasn't provided via command line, handle appropriately
if [ -z "$NOTIFICATION_EMAIL" ]; then
  if [[ "$AUTO_APPROVE" == "-auto-approve" ]]; then
    # Auto-approve is enabled, but we still need an email for the variable
    # Set a placeholder email as Terraform requires this variable
    echo "⚠️ Warning: No email provided. Notifications will be configured but no subscribers will receive them."
    NOTIFICATION_EMAIL="no-reply@example.com"
  else
    # Ask for email interactively
    echo -n "Enter email address for event notifications (leave blank to skip): "
    read -r NOTIFICATION_EMAIL
    echo
    if [ -z "$NOTIFICATION_EMAIL" ]; then
      echo "⚠️ Warning: No email provided. Notifications will be configured but no subscribers will receive them."
      echo
      # Set a placeholder email as Terraform requires this variable
      NOTIFICATION_EMAIL="no-reply@example.com"
    fi
  fi
fi

# Create a modified main.tf file that only includes IAM
echo "Creating IAM-only Terraform configuration..."

# Move to the mdftoparquet directory
cd mdftoparquet

# Create an IAM-only configuration
cat > main_iam.tf <<EOT
/**
* CANedge MDF4-to-Parquet Pipeline on Google Cloud Platform
* IAM-only configuration
*/

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.84.0"
    }
  }
  
  # Store state in input bucket
  backend "gcs" {
    prefix = "terraform/state/mdftoparquet"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# IAM service account and permissions
module "iam" {
  source = "./modules/iam"

  project          = var.project
  unique_id        = var.unique_id
  input_bucket_name = var.input_bucket_name
  output_bucket_name = "\${var.input_bucket_name}-parquet"
}
EOT

# Initialize Terraform with backend config pointing to input bucket
echo "Initializing Terraform with state stored in input bucket..."
terraform init -reconfigure \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="prefix=terraform/state/mdftoparquet"

# Import existing service account if it exists
if [ "$SA_EXISTS" = true ]; then
  echo "Importing existing service account into Terraform state..."
  terraform -chdir=. import -auto-approve -var="project=${PROJECT_ID}" \
    -var="region=${REGION}" \
    -var="input_bucket_name=${BUCKET_NAME}" \
    -var="unique_id=${UNIQUE_ID}" \
    -var="notification_email=${NOTIFICATION_EMAIL}" \
    -var="function_zip=${FUNCTION_ZIP}" \
    module.iam.google_service_account.function_service_account "projects/${PROJECT_ID}/serviceAccounts/${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" 2>&1 || echo "Warning: Failed to import service account, but continuing anyway."
fi

# Apply the IAM-only configuration
echo "Deploying IAM resources..."
terraform -chdir=. apply $AUTO_APPROVE \
  -var="project=${PROJECT_ID}" \
  -var="region=${REGION}" \
  -var="input_bucket_name=${BUCKET_NAME}" \
  -var="unique_id=${UNIQUE_ID}" \
  -var="notification_email=${NOTIFICATION_EMAIL}" \
  -var="function_zip=${FUNCTION_ZIP}" \
  -state=terraform.tfstate \
  -state-out=terraform.tfstate

# Check if the IAM deployment was successful
DEPLOY_STATUS=$?
if [ $DEPLOY_STATUS -eq 0 ]; then
  echo
  echo "---------------------------"
  echo "✅  IAM resources deployed successfully!"
  echo
  echo "Project ID:       ${PROJECT_ID}"
  echo "Region:           ${REGION}"
  echo "Input bucket:     ${BUCKET_NAME}"
  echo "Unique ID:        ${UNIQUE_ID}"
  echo
  echo "Now run deploy_mdftoparquet_2.sh with the same parameters to deploy the remaining resources."
  echo "---------------------------"
  
  # Clean up the temporary file
  rm -f main_iam.tf
else
  echo "❌ IAM deployment failed."
  # Clean up the temporary file
  rm -f main_iam.tf
  exit $DEPLOY_STATUS
fi
