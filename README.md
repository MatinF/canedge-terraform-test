# CANedge Google Cloud Platform Deployment

This repository provides Terraform configurations to automate the deployment of CANedge data processing infrastructure on Google Cloud Platform. The deployment is split into two parts:

1. **Input Bucket Deployment**: Creates an input bucket for storing uploaded CANedge log files
2. **MF4-to-Parquet Deployment**: Creates an output bucket and Cloud Function for DBC decoding MDF to Parquet

----------

## Deployment

### Deploy Input Bucket

If you're just getting started, first deploy the input bucket where your CANedge devices will upload MF4 files. Click the below URL to get started:

[One-click deployment URL](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_input_bucket.md)


### Deploy MF4-to-Parquet Pipeline

Once you have an input bucket set up, you can optionally deploy the processing pipeline to automatically DBC decode uploaded MF4 files to Parquet format. Click the below URL to get started: 

[One-click deployment URL](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/MatinF/canedge-terraform-test&cloudshell_tutorial=README_mdftoparquet.md)

----------

## Project Structure

- `input_bucket/` - Terraform configuration for input bucket deployment
- `mdftoparquet/` - Terraform configuration for MF4-to-Parquet pipeline deployment
  - `modules/` - Terraform modules specific to the MF4-to-Parquet pipeline
    - `output_bucket/` - Module for creating the output bucket
    - `iam/` - Module for setting up IAM permissions
    - `cloud_function/` - Module for deploying the Cloud Function
- `deploy_input_bucket.sh` - Script for input bucket deployment
- `deploy_mdftoparquet.sh` - Script for MF4-to-Parquet pipeline deployment

----------

## Troubleshooting

If you encounter issues with either deployment:

- Make sure you have proper permissions in your Google Cloud project
- Use unique identifiers with the `--id` parameter to avoid resource conflicts
- Check the Google Cloud Console logs for detailed error messages
- For the MF4-to-Parquet, ensure the function ZIP file is uploaded to your input bucket before deployment