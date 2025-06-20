# CANedge MDF4-to-Parquet Pipeline Deployment

Deploy pipeline to automatically decode MDF4 files to Parquet format.

## Prerequisites

- Input bucket for MDF4 files (create using `deploy_input_bucket.sh`)
- Function ZIP file uploaded to input bucket: `mdf-to-parquet-google-function-v1.5.0.zip`

## How to deploy

1. **Make the deployment script executable**:
   ```bash
   chmod +x deploy_mdftoparquet.sh
   ```

2. **Run the deployment with your project details**:
   ```bash
   ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME --id YOUR_PIPELINE_ID
   ```

   Example:
   ```bash
   ./deploy_mdftoparquet.sh --project my-project-123 --bucket canedge-test-bucket-gcp --id mypipeline
   ```

---------

### Notes/tips

- Use the `--id` parameter to uniquely identify your pipeline (e.g. for multiple deployments)
- An output bucket is auto-created with the name `YOUR_INPUT_BUCKET_NAME-parquet`
- Upload `.MF4`, `.MFC`, `.MFE`, or `.MFM` files to trigger auto-decoding
- For encrypted files (`.MFE` or `.MFM`), store `passwords.json` in the bucket root
- The Function will automatically DBC decode the file
- Decoded Parquet files will appear in your output bucket

## Updating an Existing Deployment

When updating an existing deployment (e.g., to use a newer version of the function ZIP):

1. **Use the same `--id` parameter** as your original deployment
   ```
   ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET --id YOUR_EXISTING_ID
   ```

2. Terraform will detect only the changes between versions and update just those components

3. This approach prevents resource conflicts and minimizes changes to your infrastructure

This state-aware update process is possible because Terraform stores your deployment state in the input bucket.
