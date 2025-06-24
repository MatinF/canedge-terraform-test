# Context
Read the README.md and the README_input_bucket.md. Also read the contents of input_bucket/ and deploy_input_bucket.sh. Ignore other files in this repository.

I am testing this deployment in my Google Cloud Platform account where I am the root admin. It worked previously when testing in my original existing project (with probably some different base settings).

Now I am trying to deploy in a completely new project that I created from scratch. I do this via the one-click URL in the README.md and using the single command as outlined in the README.

When I try this, I get below error:

```
csselectronics_calendar@cloudshell:~/cloudshell_open/canedge-terraform-test-11 (bigquerytest5)$ chmod +x deploy_input_bucket.sh && ./deploy_input_bucket.sh --project bigquerytest5 --region europe-west1 --bucket canedge-test-bucket-gcp-21
Setting project to 'bigquerytest5'...
Updated property [core/project].
✓ Project set to 'bigquerytest5'.
Deploying CANedge GCP Input Bucket with the following configuration:
   - Project ID:    bigquerytest5
   - Region:        europe-west1
   - Bucket Name:   canedge-test-bucket-gcp-21

Initializing Terraform with local state...

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching ">= 4.84.0"...
- Installing hashicorp/google v6.40.0...
- Installed hashicorp/google v6.40.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Applying Terraform configuration to create the input bucket...
╷
│ Error: Error creating service account: googleapi: Error 403: Identity and Access Management (IAM) API has not been used in project bigquerytest5 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/iam.googleapis.com/overview?project=bigquerytest5 then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.
│ Details:
│ [
│   {
│     "@type": "type.googleapis.com/google.rpc.ErrorInfo",
│     "domain": "googleapis.com",
│     "metadata": {
│       "activationUrl": "https://console.developers.google.com/apis/api/iam.googleapis.com/overview?project=bigquerytest5",
│       "consumer": "projects/bigquerytest5",
│       "containerInfo": "bigquerytest5",
│       "service": "iam.googleapis.com",
│       "serviceTitle": "Identity and Access Management (IAM) API"
│     },
│     "reason": "SERVICE_DISABLED"
│   },
│   {
│     "@type": "type.googleapis.com/google.rpc.LocalizedMessage",
│     "locale": "en-US",
│     "message": "Identity and Access Management (IAM) API has not been used in project bigquerytest5 before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/iam.googleapis.com/overview?project=bigquerytest5 then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry."
│   },
│   {
│     "@type": "type.googleapis.com/google.rpc.Help",
│     "links": [
│       {
│         "description": "Google developers console API activation",
│         "url": "https://console.developers.google.com/apis/api/iam.googleapis.com/overview?project=bigquerytest5"
│       }
│     ]
│   }
│ ]
│ , accessNotConfigured
│ 
│   with google_service_account.storage_admin,
│   on main.tf line 48, in resource "google_service_account" "storage_admin":
│   48: resource "google_service_account" "storage_admin" {
│ 
╵
❌  Initial deployment failed.
```


## TASK 11
 Please review what is causing this and how we can resolve it, ideally through minimal modifications. 