## CONTEXT

Our end users deploy the CANedge CAN bus data logger with WiFi/LTE, which can upload data to clouds like AWS, Google Cloud and Azure. 

This repo is a terraform stack that allows user of our  to create a new Google Cloud bucket and deploy a v2 Google Cloud Run Function based on a zip in the input bucket. The state of the terraform deployment is stored in the input bucket. It is currently assumed that the user already created the input bucket manually before using this script.

Go through the README.md for overall details, as well as the README_input_bucket.md for details on deploying an input bucket and the README_mdftoparquet.md for details on deploying the output bucket and Google Cloud Function (v2). See the README_bigquery.md for details on the bigquery terraform stack. 

----------

## Task 10
Update the bigquery/modules/cloud_function to allow HTTP trigger use by unauthenticated users, i.e. anyone on the internet. 

