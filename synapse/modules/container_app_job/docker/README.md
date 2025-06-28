# Synapse Table Mapper Docker Image

This directory contains the source code for the Synapse Table Mapper Docker image used by the Azure Container App Job.

## Overview

The Synapse Table Mapper automatically creates external tables in Synapse SQL for Parquet files stored in Azure Blob Storage. It:

1. Scans the specified container for device/message folders containing Parquet files
2. Extracts schema information from the Parquet files
3. Creates corresponding external tables in the Synapse workspace

## Docker Image

The Docker image is hosted in GitHub Container Registry at:
```
ghcr.io/martinfhotmail/canedge-synapse-map-tables:latest
```

## Building and Pushing the Docker Image

If you need to modify the script and update the Docker image, follow these steps:

1. Make your changes to the `synapse-map-tables.py` script
2. Build the Docker image:
   ```bash
   docker build -t ghcr.io/YOUR_GITHUB_USERNAME/canedge-synapse-map-tables:latest .
   ```
3. Authenticate with GitHub Container Registry:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
   ```
4. Push the image:
   ```bash
   docker push ghcr.io/YOUR_GITHUB_USERNAME/canedge-synapse-map-tables:latest
   ```
5. Update the container image URL in the Terraform variables if you've changed it:
   ```
   variable "container_image" in modules/container_app_job/variables.tf
   ```

## Environment Variables

The Docker container expects the following environment variables:

| Variable | Description |
|----------|-------------|
| STORAGE_ACCOUNT | Storage account name |
| CONTAINER_OUTPUT | Container with Parquet files |
| STORAGE_CONNECTION_STRING | Azure Storage connection string |
| SYNAPSE_SERVER | Synapse SQL server endpoint |
| SYNAPSE_PASSWORD | SQL admin password |
| MASTER_KEY_PASSWORD | Password for database master key |
| SYNAPSE_DATABASE | Database name (default: parquetdatalake) |
| SYNAPSE_USER | SQL admin username (default: sqladminuser) |

## Development Notes

- The script uses Azure Blob Storage SDK to list and access Parquet files
- It uses pyarrow to read Parquet schemas
- It connects to Synapse SQL using pymssql
- Proper error handling and logging are implemented
