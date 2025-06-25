# Context
Review README.md, deploy_mdftoparquet.sh, README_mdftoparquet.md and the contents of mdftoparquet/.

This repo deploys various assets in Google Cloud via terraform. We deploy it as described in the README.md.

We currently encounter some IAM related issues that require us to deploy the mdftoparquet two times for it to fully work, probably due to some propagation issues.

## Task 1
To better isolate the potential root cause issues, I want you to create separate deployment scripts that will allow me to first deploy the iam resources required for mdftoparquet and enable all relevant APIs (for all of the mdftoparquet modules) up front. The second deploy script should then deploy the rest of the modules. Call them deploy_mdftoparquet_1.sh and deploy_mdftoparquet_2.sh and update the README.md to include them as two separate lines when deploying the mdftoparquet deployment with the iam being the first step. Both of the sub deployment scripts should take the same input values. 

Once both scripts have been deployed, the expected result is that the full set of resources are deployed - but without any propagation issues etc.

Test