# Context
This repository contains a folder, google/. The folder contains a terraform deployment for Google Cloud.

The deployment is to be used by engineers that use the CANedge CAN bus data logger to collect raw CAN bus data (in MDF files aka MF4) and upload them to their own cloud server, in this case Google Cloud Platform. The terraform stack and deploy_input_bucket.sh enable users to easily deploy this via Google Cloud Shell once they are logged into Google Cloud with proper permissions. 

The google/ folder also contains another stack, mdftoparquet. This stack enables the deployment of a Google Cloud Function with a trigger that ensures the function is invoked whenever objects are uploaded to the Google Cloud input bucket. The stack also deploys an output bucket for storing the decoded Parquet files produced by the function. In addition, it deploys IAM policies related to these resources and monitoring functionality that allows users to provide an email for receiving event notifications when something specific happens in their function logs. There is also a deployment script for this stack called deploy_mdftoparquet.sh.

# Task 2
I now want you to create in the root of this repository a similar deployment to the mdftoparquet from the google/ folder, but this time for Azure. Specifically, this should enable users to follow the step-by-step guidance I provide in the README.md to deploy the mdftoarquet stuff. As part of this, the users will need to provide various input information.

The cloud function will be upload by the user in the input container that he creates in the previous step. 

See the updated README.md for details on how to deploy this MF4 to Parquet pipeline from the user's perspective. 

Important:

Previously, the user would deploy the azure function as described below:

```
5: Modify and deploy Azure Function
Install the Azure CLI (to enable authentication)
Install Azure Functions Core Tools (for publishing Azure Functions)
Create a local folder called azure-function-deployment
Download and unzip our ready-to-use Azure Function below in the folder
Open the function_app.py file with a text editor
Update the input-container-name and output-container-name to match your containers[5]
If your log files are compressed, change the MF4 suffix[4]
In the mdf-to-parquet folder, open your command line
Run az login to authenticate
Run func azure functionapp publish <your-function-app-name> --python[6]
Verify that the MdfToParquet function is in your Azure Function App overview

```

This helped ensure that the function app was deployed with the proper requirements installed, in this case including below:
``` 
azure-functions
azure-storage-blob
pyarrow
pandas
```

Ideally we want to achieve the same result when deploying the function via terraform, i.e. the dependencies from the requirements.txt should be installed as part of the deployment, even if the zip does not include these pre-built (but only provides the requirements.txt). 

Comments:
- The Azure Function App should use 'Consumption' as the type
- The function name should be mdf-to-parquet-{ID} using the provided ID from the user 
- It should use Linux and Python 3.11
- I have stored the current function code in the info/azure-function/ folder. The function currently relies on ENV variables, specifically STORAGE_CONNECTION_STRING and BUCKET_INPUT and MDF_EXTENSION (set this to `MF4` as the default for now for simplicity as we may remove this later). Note that because we incorporate teh STORAGE_CONNECTION_STRING in this way, I expect a lot of the IAM stuff from the Google example will not be relevant.
- Also avoid implementing the monitoring terraform stack from the google example for now
- The Google shell script for mdftoparquet has quite a bit of handling related to API enablement and some retry handling for cases related specifically to google - avoid including this type of stuff until we find it to be necessary. 


NOTE: I have added in info/function-app-syntax.txt the official terraform syntax on creating a function app - refer to this to ensure you're using the relevant syntax when deploying. 

Create a step-by-step detailed plan and use it as reference before you proceed to deploying the relevant stacks and deployment shell script. Update the README.md if needed to reflect changes. Avoid suppressing output in the shell script. 