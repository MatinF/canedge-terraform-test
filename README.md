# CANedge MDF4-to-Parquet Pipeline - Cloud Deployment

## What this does

This deployment automates the setup of an MF4-to-Parquet decoding pipeline in Google Cloud Platform:

1. An **output bucket** for storing decoded Parquet files
2. A **Cloud Function** that auto-decodes CANedge MDF files when uploaded
3. Necessary **IAM permissions** required for the function

## Prerequisites

Before deploying, please ensure you have:

- ✅ Created your input bucket for MDF4 files
- ✅ Uploaded the `mdf-to-parquet-google-function-v1.3.0.zip` file to the root of your input bucket
- ✅ Noted the region where your input bucket is located (e.g., `europe-west4`)

## Deployment Instructions

1. **Run the deployment with your project and bucket details**:

   ```bash
   ./deploy.sh --project YOUR_PROJECT_ID --region YOUR_BUCKET_REGION --bucket YOUR_INPUT_BUCKET_NAME
   ```

   For example, if your GCP project ID is `my-project-123`, your input bucket is named `canedge-test-bucket-gcp` and located in `europe-west4`:

   ```bash
   ./deploy.sh --project my-project-123 --region europe-west4 --bucket canedge-test-bucket-gcp
   ```

2. **When prompted, type `yes` to proceed with the deployment**

## Important Notes

- You must specify your GCP project ID with the `--project` parameter
- The output bucket will be named `YOUR_INPUT_BUCKET_NAME-parquet`
- Your region **must match** the region where your input bucket is located

## After Deployment

1. **Enable Hierarchical Namespace** on the output bucket (optional):
   - Navigate to your newly created output bucket in the Google Cloud Console
   - Go to the "Configuration" tab
   - Find the Hierarchical Namespace setting and enable it

2. Upload an MDF4 file (`.MF4`, `.MFC`, `.MFE`, or `.MFM`) to your input bucket
3. The Cloud Function will automatically process the file
4. Converted Parquet files will appear in your output bucket

## Troubleshooting

If you encounter issues:

- Verify the function ZIP file is correctly uploaded to your input bucket root
- Check that the region specified matches your input bucket's region
- Ensure your active GCP project has the necessary APIs enabled

## One-Click Deployment URL

You can launch Google Cloud Shell with this repository pre-cloned and the script already made executable using the URL below:

```
https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README.md&cloudshell_command=chmod%20%2Bx%20deploy.sh
```