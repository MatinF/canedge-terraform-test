# CANedge Input Bucket Deployment

## What this does

This will auto-create an input bucket for connecting your CANedge devices. Based on your inputs it will create:

1. An **input bucket** for uploading MDF4 files from your CANedge devices
2. Apply **CORS settings** to allow access via CANcloud
3. Output **S3 details** for configuring your CANedge

## Deployment Instructions

1. **Make the deployment script executable**:

   ```bash
   chmod +x deploy_input_bucket.sh
   ```

2. **Run the deployment with your project details**:

   ```bash
   ./deploy_input_bucket.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET_NAME
   ```

   For example, to create a bucket named `canedge-test-bucket-gcp` in region `europe-west1` (see [this link](https://cloud.google.com/storage/docs/locations#location-r) for available regions):

   ```bash
   ./deploy_input_bucket.sh --project my-project-123 --region europe-west1 --bucket canedge-test-bucket-gcp
   ```

3. **When prompted, type `yes` to proceed with the deployment**

## Important Notes

- The bucket will be created with CORS settings that allow access from any origin (needed for CANedge devices)
- The deployment will create S3 interoperability credentials for use with your CANedge devices
- Terraform state is stored locally, making the setup simpler
- Choose a globally unique bucket name that follows Google Cloud naming requirements

## After Deployment

After successful deployment, you will receive:

1. The Google Cloud Storage endpoint: http://storage.googleapis.com on port 80
2. Your bucket name and region
3. S3 interoperability access key and instructions to view the secret key

These credentials can be used to configure your CANedge devices for cloud upload.

## Next Steps

After creating your input bucket:

1. Configure your CANedge device with the S3 credentials provided
2. Deploy the MDF4-to-Parquet pipeline to automatically decode your data using the `deploy_mdftoparquet.sh` script

## One-Click Deployment URL

You can launch Google Cloud Shell with this repository pre-cloned using the URL below:

```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_input_bucket.md
```
