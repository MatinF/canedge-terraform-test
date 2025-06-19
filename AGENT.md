## CONTEXT

Our end users deploy the CANedge CAN bus data logger with WiFi/LTE, which can upload data to clouds like AWS, Google Cloud and Azure. 

This repo is a terraform stack that allows user of our  to create a new Google Cloud bucket and deploy a v2 Google Cloud Run Function based on a zip in the input bucket. The state of the terraform deployment is stored in the input bucket. It is currently assumed that the user already created the input bucket manually before using this script.

## TASK 1
I would like to extend the functioality of this repository so that the user can also use the same repo (but a different deploy.sh and different README.md called deploy_input_bucket.sh and README_input_bucket.md) to deploy the input bucket itself.

I expect this will require that you restructure the repo a bit first. Think of this as a multi-step approach:

1) A user may initially just want to deploy the input bucket. For this he should provide a Google project ID, bucket name and a region (single region) and an ID - that's it.

The bucket should be created with the below CORS settings applied:
 '[{"maxAgeSeconds": 3600, "method": ["GET", "OPTIONS", "HEAD", "PUT", "POST", "DELETE"],
"origin": ["*"], "responseHeader": ["*"]}]'

The output when completed should include the endpoint: http://storage.googleapis.com, port: 80, bucket name, region and the S3 interoperability access key and secret key

As the script does now, the state of terraform should be stored in the input bucket.

There should be a one stop URL provided in the README for this step. I'm thinking the related files could be stored in input_bucket/ or something similar.

3) the same user may then later want to deploy the output bucket and cloud function (i.e. basically the stuff we've created in the repo now, just renaming the deploy.sh to deploy_mdftoparquet.sh and README_mdftoparquet.sh. It may make sense to shift the root main.tf, outputs.tf and variables.tf into some subfolder structure called mdftoparquet/ or similar 

4) Create an overall README.md that explains the sub steps and includes the one stop URLs that allow users to e.g. deploy just the input bucket - and the URL that allows them to deploy the output bucket + function. Further extensions may be added later.


