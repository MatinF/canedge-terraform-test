# CANedge Google Cloud Platform Deployment

This repository provides Terraform configurations to automate the deployment of CANedge data processing infrastructure on Google Cloud Platform. The deployment is split into two parts:

1. **Input Bucket Deployment**: Creates a Google Cloud Storage bucket with proper CORS settings for CANedge device uploads
2. **MDF4-to-Parquet Pipeline Deployment**: Sets up the data processing pipeline using Google Cloud Functions

## Deployment

### Deploy Input Bucket

If you're just getting started, first deploy the input bucket where your CANedge devices will upload MDF4 files.

```bash
./deploy_input_bucket.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET_NAME
```

Detailed instructions: [Input Bucket Deployment Guide](README_input_bucket.md)

One-click deployment URL:
```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_input_bucket.md
```

### Deploy MDF4-to-Parquet Pipeline

Once you have an input bucket set up, deploy the processing pipeline to automatically decode uploaded MDF4 files to Parquet format.

```bash
./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME --id YOUR_UNIQUE_ID
```

Detailed instructions: [MDF4-to-Parquet Deployment Guide](README_mdftoparquet.md)

One-click deployment URL:
```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_mdftoparquet.md
```

## Complete Deployment Workflow

For a complete setup, follow these steps:

1. **Create Input Bucket**:
   ```bash
   chmod +x deploy_input_bucket.sh
   ./deploy_input_bucket.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET_NAME
   ```

2. **Configure your CANedge devices** using the S3 interoperability credentials provided during input bucket deployment

3. **Upload the cloud function ZIP file** to your input bucket:
   ```bash
   gsutil cp mdf-to-parquet-google-function-v1.4.0.zip gs://YOUR_BUCKET_NAME/
   ```

4. **Deploy MDF4-to-Parquet Pipeline**:
   ```bash
   chmod +x deploy_mdftoparquet.sh
   ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --bucket YOUR_BUCKET_NAME --id YOUR_UNIQUE_ID
   ```

5. **Test the workflow** by uploading an MDF4 file to your input bucket and checking for the decoded Parquet files in the output bucket

## Project Structure

- `input_bucket/` - Terraform configuration for input bucket deployment
- `mdftoparquet/` - Terraform configuration for MDF4-to-Parquet pipeline deployment
  - `modules/` - Terraform modules specific to the MDF4-to-Parquet pipeline
    - `output_bucket/` - Module for creating the output bucket
    - `iam/` - Module for setting up IAM permissions
    - `cloud_function/` - Module for deploying the Cloud Function
- `deploy_input_bucket.sh` - Script for input bucket deployment
- `deploy_mdftoparquet.sh` - Script for MDF4-to-Parquet pipeline deployment

## Recommended Regions

For optimal performance and pricing, we recommend the following regions:
- Europe: `europe-west1` (Belgium) or `europe-west4` (Netherlands)
- North America: `us-central1` (Iowa) or `us-east4` (Northern Virginia)
- Asia: `asia-east1` (Taiwan) or `asia-southeast1` (Singapore)

## Troubleshooting

If you encounter issues with either deployment:

- Make sure you have proper permissions in your Google Cloud project
- Use unique identifiers with the `--id` parameter to avoid resource conflicts
- Check the Google Cloud Console logs for detailed error messages
- For the MDF4-to-Parquet pipeline, ensure the function ZIP file is uploaded to your input bucket
- The region is automatically detected from your input bucket for the MDF4-to-Parquet deployment (no need to specify it)