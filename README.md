# CANedge Azure Cloud Platform Deployment

This repository provides Terraform configurations to automate the deployment of CANedge data processing infrastructure on Azure.

1. **Input Container Deployment**: Creates an input container for storing uploaded CANedge log files
2. **MF4-to-Parquet Deployment**: Creates an output container and Azure Function for DBC decoding MDF to Parquet

----------

## Deployment

### Setup Instructions

1. Log in to [Azure](https://portal.azure.com/#home)
3. Click on the Cloud Shell icon (>_) to open Cloud Shell (top right) and select 'Bash'
4. Once Cloud Shell is open, run below command to clone this repository (paste via **ctrl+shift+v**):

```bash
cd ~ && rm -rf canedge-azure-cloud-terraform && git clone https://github.com/CSS-Electronics/canedge-azure-cloud-terraform.git && cd canedge-azure-cloud-terraform
```


&nbsp;

### 1: Deploy Input Container

If you're just getting started, first deploy the input container where your CANedge devices will upload MF4 files:

```bash
chmod +x deploy_input_container.sh && ./deploy_input_container.sh --resourcegroup YOUR_RESOURCE_GROUP --storageaccount YOUR_STORAGE_ACCOUNT --region YOUR_REGION --container YOUR_CONTAINER_NAME
```

Replace:
- `YOUR_RESOURCE_GROUP` with your desired resource group (e.g. `canedge-resources`)
- `YOUR_STORAGE_ACCOUNT` with your desired storage account, existing or new (e.g. `canedgestorage1`)
- `YOUR_REGION` with your desired region (e.g., `germanywestcentral` - see [this link](https://azuretracks.com/2021/04/current-azure-region-names-reference/) for available regions)
- `YOUR_CONTAINER_NAME` with your desired container name (e.g. `canedge-test-container-20`)

Optional parameters:
- `--subid YOUR_SUBSCRIPTION_ID` to specify a particular Azure subscription ID (e.g. `ff652281-fac4-4dbb-b2ba-819cdf28ac83`). If not provided, your default subscription will be used.


&nbsp;

### 2: Deploy MF4-to-Parquet Pipeline

Once you have an input container set up, you can optionally deploy the processing pipeline to automatically DBC decode uploaded MF4 files to Parquet format:

```bash
chmod +x deploy_mdftoparquet.sh && ./deploy_mdftoparquet.sh --resourcegroup YOUR_RESOURCE_GROUP --storageaccount YOUR_STORAGE_ACCOUNT --container YOUR_INPUT_CONTAINER_NAME --id YOUR_UNIQUE_ID --email YOUR_EMAIL --zip YOUR_FUNCTION_ZIP

```

Replace:
- `YOUR_RESOURCE_GROUP` with your input container resource group from step 1 (e.g. `canedge-resources`)
- `YOUR_STORAGE_ACCOUNT` with your input storage account from step 1 (e.g. `canedgestorage1`)
- `YOUR_INPUT_CONTAINER_NAME` with your input container name from step 1 (e.g. `canedge-test-container-20`)
- `YOUR_UNIQUE_ID` with a short unique identifier (e.g. `datalake1`)
- `YOUR_EMAIL` with your email address to receive notifications
- `YOUR_FUNCTION_ZIP` with the function ZIP file name (e.g. `mdf-to-parquet-azure-function-v3.1.0.zip`)
  - *Download the ZIP from the [CANedge Intro](https://www.csselectronics.com/pages/can-bus-hardware-software-docs) (Process/MF4 decoders/Parquet data lake/Azure)*


> [!NOTE]  
> Make sure to upload the ZIP to your input container root before deployment 

&nbsp;