# CANedge BigQuery Analytics Deployment

Deploy BigQuery resources for querying your CANedge Parquet data lake.

## Prerequisites

- Input bucket for MDF files (create using `deploy_input_bucket.sh`)
- Parquet data lake (deploy using `deploy_mdftoparquet.sh`)

## How to deploy

**Run the deployment with one command**:
```bash
chmod +x deploy_bigquery.sh && ./deploy_bigquery.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME
```

Example:
```bash
chmod +x deploy_bigquery.sh && ./deploy_bigquery.sh --project my-project-123 --bucket canedge-test-bucket-gcp
```

---------

### Notes/tips

- Use the `--id` parameter to uniquely identify your BigQuery resources
- Use `--dataset` to specify a custom dataset name (default: `lakedataset1`)
- Region is auto-detected from your input bucket
- Two service account keys are created and stored in your input bucket:
  - Admin key: `<unique-id>-bigquery-admin-account.json`
  - User key: `<unique-id>-bigquery-user-account.json`
- Use the admin key for table management and the user key for querying
- Access BigQuery through the [Google Cloud Console](https://console.cloud.google.com/bigquery)

## Updating an Existing Deployment

When updating an existing deployment:

1. **Use the same `--id` parameter** as your original deployment
   ```bash
   ./deploy_bigquery.sh --project YOUR_PROJECT_ID --bucket YOUR_BUCKET --id YOUR_EXISTING_ID
   ```

2. Terraform will detect changes between versions and update only those components

This state-aware update process is possible because Terraform stores your deployment state in the input bucket.
