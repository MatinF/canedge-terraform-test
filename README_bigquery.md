# CANedge BigQuery Deployment

Deploy BigQuery to query your Parquet data lake.

## Prerequisites

- Input bucket for CANedge MDF files 
- Output bucket for DBC decoded Parquet files

## How to deploy

```bash
chmod +x deploy_bigquery.sh && ./deploy_bigquery.sh \
   --project YOUR_PROJECT_ID \
   --bucket YOUR_INPUT_BUCKET_NAME \
   --id YOUR_UNIQUE_ID \
   --dataset YOUR_DATASET_NAME
```

Example:
```bash
chmod +x deploy_bigquery.sh && ./deploy_bigquery.sh \
   --project my-project-123 \
   --bucket canedge-test-bucket-gcp \
   --id canedge-demo \
   --dataset lakedataset1
```

---------

### Notes/tips

- The `--id` parameter is required to uniquely identify your BigQuery resources
- The `--dataset` parameter is required to name your BigQuery dataset
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
