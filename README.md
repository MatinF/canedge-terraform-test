# CANedge Google Cloud Platform Deployment

This repository provides Terraform configurations to automate the deployment of CANedge data processing infrastructure on Google Cloud Platform. The deployment is split into three parts:

1. **Input Bucket Deployment**: Creates an input bucket for storing uploaded CANedge log files
2. **MF4-to-Parquet Deployment**: Creates an output bucket and Cloud Function for DBC decoding MDF to Parquet
3. **BigQuery Deployment**: Creates BigQuery resources for querying Parquet data

----------

## Deployment

### Setup Instructions

![Google Cloud Console showing Project ID and Shell](http://canlogger1000.csselectronics.com/img/GCP-console-project-id-shell.png)

1. Log in to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project from the dropdown (top left)
3. Click on the Cloud Shell icon (>_) to open Cloud Shell (top right)
4. Once Cloud Shell is open, run the following command to clone this repository:

```bash
cd ~ && rm -rf canedge-google-cloud-terraform && git clone https://github.com/CSS-Electronics/canedge-google-cloud-terraform.git && cd canedge-google-cloud-terraform
```


### 1: Deploy Input Bucket

If you're just getting started, first deploy the input bucket where your CANedge devices will upload MF4 files:

```bash
chmod +x deploy_input_bucket.sh && ./deploy_input_bucket.sh --project YOUR_PROJECT_ID --region YOUR_REGION --bucket YOUR_BUCKET_NAME
```

Replace:
- `YOUR_PROJECT_ID` with your Google Cloud project ID (click your project to see this)
- `YOUR_REGION` with your desired region (e.g., `europe-west1` - see [this link](https://cloud.google.com/storage/docs/locations#location-r) for available regions)
- `YOUR_BUCKET_NAME` with your desired bucket name (should be globally unique)



### 2: Deploy MF4-to-Parquet Pipeline

Once you have an input bucket set up, you can optionally deploy the processing pipeline to automatically DBC decode uploaded MF4 files to Parquet format:

```bash
chmod +x deploy_mdftoparquet.sh && ./deploy_mdftoparquet.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME --id YOUR_UNIQUE_ID --email YOUR_EMAIL --zip YOUR_FUNCTION_ZIP
```

Replace:
- `YOUR_PROJECT_ID` with your Google Cloud project ID
- `YOUR_INPUT_BUCKET_NAME` with your input bucket name created in the previous step
- `YOUR_UNIQUE_ID` with a unique identifier (used for service account naming)
- `YOUR_EMAIL` with your email address to receive notifications
- `YOUR_FUNCTION_ZIP` with the function ZIP file name (`mdf-to-parquet-google-function-v3.X.X.zip`)


### 3: Deploy BigQuery

After setting up the MF4-to-Parquet pipeline, you can deploy BigQuery to query your Parquet data lake:

```bash
chmod +x deploy_bigquery.sh && ./deploy_bigquery.sh --project YOUR_PROJECT_ID --bucket YOUR_INPUT_BUCKET_NAME --id YOUR_UNIQUE_ID --dataset YOUR_DATASET_NAME --zip YOUR_FUNCTION_ZIP
```

Replace:
- `YOUR_PROJECT_ID` with your Google Cloud project ID
- `YOUR_INPUT_BUCKET_NAME` with your input bucket name
- `YOUR_UNIQUE_ID` with the same unique identifier used in the previous step
- `YOUR_DATASET_NAME` with your desired BigQuery dataset name
- `YOUR_FUNCTION_ZIP` with the BigQuery function ZIP file name (`bigquery-map-tables-vX.X.X.zip`)

----------

## Troubleshooting

If you encounter issues with either deployment:

- Make sure you have proper permissions in your Google Cloud project
- Use unique identifiers with the `--id` parameter to avoid resource conflicts
- Check the Google Cloud Console logs for detailed error messages
- For the MF4-to-Parquet and BigQuery deployments, ensure the relevant function ZIP files are uploaded to your input bucket before deployment

----------

## Project Structure

- `input_bucket/` - Terraform configuration for input bucket deployment
- `mdftoparquet/` - Terraform configuration for MF4-to-Parquet pipeline deployment
  - `modules/` - Terraform modules specific to the MF4-to-Parquet pipeline
    - `output_bucket/` - Module for creating the output bucket
    - `iam/` - Module for setting up IAM permissions
    - `cloud_function/` - Module for deploying the Cloud Function
    - `monitoring/` - Module for setting up monitoring configurations
- `bigquery/` - Terraform configuration for BigQuery deployment
  - `modules/` - Terraform modules specific to the BigQuery deployment
    - `dataset/` - Module for creating the BigQuery dataset
    - `service_accounts/` - Module for setting up service accounts
    - `cloud_function/` - Module for deploying the BigQuery mapping function
- `bigquery-function/` - Source code for BigQuery table mapping function
- `deploy_input_bucket.sh` - Script for input bucket deployment
- `deploy_mdftoparquet.sh` - Script for MF4-to-Parquet pipeline deployment
- `deploy_bigquery.sh` - Script for BigQuery deployment
