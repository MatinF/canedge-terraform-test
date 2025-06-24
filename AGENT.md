## CONTEXT

Our end users deploy the CANedge CAN bus data logger with WiFi/LTE, which can upload data to clouds like AWS, Google Cloud and Azure. 

This repo is a terraform stack that allows user of our  to create a new Google Cloud bucket and deploy a v2 Google Cloud Run Function based on a zip in the input bucket. The state of the terraform deployment is stored in the input bucket. It is currently assumed that the user already created the input bucket manually before using this script.

Go through the README.md for overall details, as well as the README_input_bucket.md for details on deploying an input bucket and the README_mdftoparquet.md for details on deploying the output bucket and Google Cloud Function (v2). See the README_bigquery.md for details on the bigquery terraform stack. 

----------

## Task 6
In info/ there is a Python script that is used for mapping tables in BigQuery, bigquery-map-tables.py. Currently this is used offline by downloading the ADMIN_KEY_FILE created in deploy_big_query.sh. The info/requirements.txt relates to the requirements for this.

I want now to have this modified into a Google Cloud Function (v2) script. This will then be zipped with the requirements.txt and uploaded by the user into the input bucket, named bigquery-map-tables-v1.0.0.zip.

Update the script with this in mind and ensure it has the proper use of ENV variables for credentials etc. You can look at another Cloud Function I added in info called main.py for inspiration, this is used in the mdftoparquet deployment (along with some other functions). Avoid excessively editing the table mapping logic in the script, but focus on the initial section to streamline this for use in the function environment - I imagine some significant simplifications can be made. Assume that any ENV variables will be added to the cloud Function. If it's possible to avoid too many ENV variables by simply initializing e.g. the storage client as in the main.py and instead handling this via some modifications to the bigquery Terraform stack deployment of IAM resources that may be best. The goal is to keep the script initialization as simple as possible. 

## Task 7
Once the function is updated, extend the current BigQuery TerraForm stack so that it also deploys a v2 Cloud Function. Look at the existing mdftoparquet/modules/cloud_function for inspiration. The timeout should be 60 min, the ram should be 1 GB, the trigger should be a HTTP request so that users can simply open a URL in the browser to trigger the function. The relevant trigger URL should be output as part of the BigQuery deployment. 

