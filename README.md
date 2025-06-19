# CANedge MDF4-to-Parquet Pipeline - Cloud Deployment

## What this does

This deployment automates the setup of a complete MDF4-to-Parquet conversion pipeline on Google Cloud Platform, consisting of:

1. An **output bucket** with Hierarchical Namespace for storing converted Parquet files
2. A **Cloud Function** that automatically processes your CANedge MDF4 files when uploaded
3. All necessary **IAM permissions** to ensure the system works seamlessly

## Prerequisites

Before deploying, please ensure you have:

- ✅ Created your input bucket for MDF4 files
- ✅ Uploaded the `mdf-to-parquet-google-function-v1.3.0.zip` file to the root of your input bucket
- ✅ Noted the region where your input bucket is located (e.g., `europe-west4` for Amsterdam)

## Deployment Instructions

1. **Make the deployment script executable**:

   ```bash
   chmod +x deploy.sh
   ```

2. **Run the deployment with your bucket details**:

   ```bash
   ./deploy.sh --region YOUR_BUCKET_REGION --bucket YOUR_INPUT_BUCKET_NAME
   ```

   For example, if your input bucket is named `canedge-test-bucket-gcp` and located in Amsterdam:

   ```bash
   ./deploy.sh --region europe-west4 --bucket canedge-test-bucket-gcp
   ```

3. **When prompted, type `yes` to proceed with the deployment**

## Important Notes

- This script uses your **currently active GCP project** for deployment
- The output bucket will be named `YOUR_INPUT_BUCKET_NAME-parquet`
- Your region **must match** the region where your input bucket is located

## After Deployment

1. Upload an MDF4 file (`.MF4`, `.MFC`, `.MFE`, or `.MFM`) to your input bucket
2. The Cloud Function will automatically process the file
3. Converted Parquet files will appear in your output bucket

## Troubleshooting

If you encounter issues:

- Verify the function ZIP file is correctly uploaded to your input bucket root
- Check that the region specified matches your input bucket's region
- Ensure your active GCP project has the necessary APIs enabled