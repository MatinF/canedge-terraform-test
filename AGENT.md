## CONTEXT

Our end users deploy the CANedge CAN bus data logger with WiFi/LTE, which can upload data to clouds like AWS, Google Cloud and Azure. 

This repo is a terraform stack that allows user of our  to create a new Google Cloud bucket and deploy a v2 Google Cloud Run Function based on a zip in the input bucket. The state of the terraform deployment is stored in the input bucket. It is currently assumed that the user already created the input bucket manually before using this script.

See the README.md for overall details, as well as the README_input_bucket.md for details on deploying an input bucket and the README_mdftoparquet.md for details on deploying the output bucket and Google Cloud Function (v2). 

## Task 5
I now need you to add a separate folder called bigquery. This should deploy BigQuery related resources via Terraform. This deployment should not be directly linked to the other existing deployments in terms of state etc, but should have its own state stored in the input bucket under terraform/state/bigquery. 

The deployment is a GCP equivalent to the AWS Athena deployment, which you will find in info/delta-glue-athena-vG.3.0.json. For details on the BigQuery settings etc, see the info/google-bigquery.rst. Essentially I am looking for this to be auto deployed instead of the user having to deploy it manually. 

Create a deployment sh file and README for this deployment, and update the README.md with a new quick link like the other deployments.

