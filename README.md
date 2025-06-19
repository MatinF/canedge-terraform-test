# CANedge GCP Terraform Stack

This repository provides a Terraform-based deployment for setting up the CANedge MDF4-to-Parquet pipeline on Google Cloud Platform (GCP). It automates the deployment of an output bucket and Cloud Function to process CANedge log files in Google Cloud.

## 🧱 Stack Components

This deployment sets up:

1. **Output Bucket**: Stores decoded Parquet files (auto-named as `<inputbucket>-parquet`).
2. **Cloud Function**: Triggered on new MDF4 uploads, runs DBC decoding (Python 3.11).
3. **IAM Service Account**: Grants Cloud Function required access to buckets and logging.

## 📋 Prerequisites

- Google Cloud Platform account with an existing project
- Existing input bucket with MDF4 files (e.g., `canedge-test-bucket-gcp`)
- The MDF4-to-Parquet function ZIP file uploaded to your input bucket root as `mdf-to-parquet-google-function-v1.3.0.zip`

## 🚀 Deployment Instructions

### One-Command Deployment (Recommended)

1. **Access Google Cloud Console**:
   - Log in to [https://console.cloud.google.com](https://console.cloud.google.com)
   - Click the `Activate Cloud Shell` button in the top-right corner

2. **Clone the repository and run the deployment script in one step**:
   ```bash
   git clone https://github.com/MatinF/canedge-terraform-test.git && \
   cd canedge-terraform-test && \
   chmod +x deploy.sh && \
   ./deploy.sh --project YOUR_PROJECT_ID --region europe-west4 --bucket canedge-test-bucket-gcp
   ```
   
   This will:
   - Clone the repository
   - Make the deployment script executable
   - Deploy all resources with your specified parameters

3. **Confirm the deployment** when prompted or add `--auto-approve` to skip confirmation

4. **Verify the outputs** for the names of created resources

### Manual Deployment (Alternative)

1. **Access Google Cloud Console**:
   - Log in to [https://console.cloud.google.com](https://console.cloud.google.com)
   - Click the `Activate Cloud Shell` button in the top-right corner

2. **Clone this repository**:
   ```bash
   git clone https://github.com/MatinF/canedge-terraform-test.git
   cd canedge-terraform-test
   ```

3. **Deploy with command-line variables**:
   ```bash
   terraform init
   terraform apply \
     -var="project=YOUR_PROJECT_ID" \
     -var="region=europe-west4" \
     -var="input_bucket_name=canedge-test-bucket-gcp" \
     -var="unique_id=canedge-demo"
   ```

4. **Confirm the deployment** by typing `yes` when prompted

## 📂 Repository Structure

```
.
├── env/
│   └── playground/         # Sample environment configuration
│       └── terraform.tfvars # Environment-specific variables
│
├── modules/
│   ├── buckets/            # Output bucket module
│   │   ├── main.tf         # Bucket resource definitions
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module input variables
│   │
│   ├── cloud_function/     # Cloud Function module
│   │   ├── main.tf         # Function resource definitions
│   │   ├── outputs.tf      # Module outputs
│   │   └── variables.tf    # Module input variables
│   │
│   └── iam/                # IAM module
│       ├── main.tf         # Service accounts and permissions
│       ├── outputs.tf      # Module outputs
│       └── variables.tf    # Module input variables
│
├── main.tf                 # Root module calling child modules
├── variables.tf            # Root input variables
├── outputs.tf              # Root outputs
└── README.md               # This file
```

## 🧪 Testing Instructions

To test your deployment with an input bucket stored in the Amsterdam region (`europe-west4`) named `canedge-test-bucket-gcp`:

1. **Deploy with a single command**:
   ```bash
   ./deploy.sh --project YOUR_PROJECT_ID --region europe-west4 --bucket canedge-test-bucket-gcp
   ```

   This will automatically configure the deployment for the Amsterdam region with your specified bucket name.

2. **Or use Terraform directly** with variables:
   ```bash
   terraform init
   terraform apply \
     -var="project=YOUR_PROJECT_ID" \
     -var="region=europe-west4" \
     -var="input_bucket_name=canedge-test-bucket-gcp"
   ```

3. **Upload the function code** (if not already uploaded):
   - Upload `mdf-to-parquet-google-function-v1.3.0.zip` to the root of your input bucket

4. **Test the function**:
   - Upload an MDF4 file (extension `.MF4`, `.MFC`, `.MFE`, or `.MFM`) to your input bucket
   - Monitor the Cloud Function execution in the GCP Console:
     - Navigate to `Cloud Functions` > `<your-function-name>` > `Logs`

5. **Verify output**:
   - Check the output bucket (`canedge-test-bucket-gcp-parquet`) for the generated Parquet files

## 🔍 Troubleshooting

- **Function not triggering**: Verify the function ZIP file is correctly uploaded to the input bucket root
- **Permission errors**: Check IAM permissions for the created service account
- **Region issues**: Ensure all resources are deployed in the same region as your input bucket

## 📤 One-Click Deployment

You can launch Cloud Shell with this repository pre-cloned using this direct URL:

```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README.md
```

After clicking the link above and opening Cloud Shell, make the deployment script executable and run it with your parameters:

```bash
chmod +x deploy.sh
./deploy.sh --project YOUR_PROJECT_ID --region REGION --bucket INPUT_BUCKET_NAME
```

For example, to deploy in Amsterdam region with a bucket named "canedge-test-bucket-gcp":

```bash
./deploy.sh --project my-gcp-project-123 --region europe-west4 --bucket canedge-test-bucket-gcp
```

To see all available options:

```bash
./deploy.sh --help
```