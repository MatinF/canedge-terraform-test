# CANedge Azure Cloud Platform Deployment

This repository provides Terraform configurations to automate the deployment of CANedge data processing infrastructure on Azure.

1. **Input Container Deployment**: Creates an input container for storing uploaded CANedge log files


----------

## Deployment

### Setup Instructions

1. Log in to [Azure](https://portal.azure.com/#home)
3. Click on the Cloud Shell icon (>_) to open Cloud Shell (top right) and select 'Bash'
4. Once Cloud Shell is open, run the following command to clone this repository:

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

&nbsp;
