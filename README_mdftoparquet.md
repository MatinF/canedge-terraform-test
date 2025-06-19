# CANedge MF4-to-Parquet Pipeline - Google Cloud Deployment

## What this does

This repository contains Terraform configuration to automate the deployment of a CANedge MDF4-to-Parquet conversion pipeline on Google Cloud Platform using Cloud Functions 2nd generation.

When deployed, it creates:
1. An **output bucket** for storing decoded Parquet files
2. A **Cloud Function** that auto-decodes CANedge MDF files when uploaded
3. Necessary **IAM permissions** required for the function

## Prerequisites

Before deploying, please ensure you have:

- Created your input bucket for MDF4 files (you can use the `deploy_input_bucket.sh` script provided)
- Uploaded the `mdf-to-parquet-google-function-v1.4.0.zip` file to the root of your input bucket
- Noted the region where your input bucket is located (e.g., `europe-west4`)

## Deployment Instructions

1. **Make the deployment script executable**:

   ```bash
   chmod +x deploy_mdftoparquet.sh
   ```

2. **Run the deployment with your project and bucket details**:

   ```bash
   ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME --id YOUR_PIPELINE_NAME
   ```

   For example, if your GCP project ID is `my-project-123` and your input bucket is named `canedge-test-bucket-gcp`:

   ```bash
   ./deploy_mdftoparquet.sh --project my-project-123 --bucket canedge-test-bucket-gcp --id my-canedge
   ```
   
   The script will automatically detect the region of your input bucket.

3. **When prompted, type `yes` to proceed with the deployment**

## Important Notes

- You must specify your GCP project ID with the `--project` parameter
- The output bucket will be named `YOUR_INPUT_BUCKET_NAME-parquet`
- The region is automatically detected from your input bucket
- You can still manually specify a region with `--region` if needed
- Use a unique `--id` parameter to avoid conflicts when deploying multiple pipelines or redeploying

## After Deployment
1. Upload an MDF4 file (`.MF4`, `.MFC`, `.MFE`, or `.MFM`) to your input bucket (if you're uploading `.MFE` or `.MFM`, ensure your `passwords.json` file is stored in the root of the input bucket)
2. The Cloud Function will automatically DBC decode the file
3. Decoded Parquet files will appear in your output bucket

## Troubleshooting

If you encounter issues:

- **Service account already exists error**: Use a unique `--id` parameter to create resources with different names:
  ```
  ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET --id YOUR_PIPELINE_NAME
  ```
- Verify the function ZIP file is correctly uploaded to your input bucket root

## One-Click Deployment URL

You can launch Google Cloud Shell with this repository pre-cloned using the URL below:

```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_mdftoparquet.md
```

## Updating an Existing Deployment

When updating an existing deployment (e.g., to use a newer version of the function ZIP):

1. **Use the same `--id` parameter** as your original deployment
   ```
   ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET --id YOUR_EXISTING_ID
   ```

2. Terraform will detect only the changes between versions and update just those components

3. This approach prevents resource conflicts and minimizes changes to your infrastructure

This state-aware update process is possible because Terraform stores your deployment state in the input bucket.
