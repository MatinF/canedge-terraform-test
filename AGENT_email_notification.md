# Context
This repository contains terraform stacks and deployment scripts for deploying resources in Azure via the 'bash' cloud shell environment. See the README.md for details and go through all files in mdftoparquet/ as well as teh deploy_mdftoparquet.sh.

The mdftoparquet folder contains a deployment stack for deploying an Azure function. The user uploads a zip with the function contents into the input container. The deployment then fetches this and deploys it in an Azure Function App. It also deploys an output bucket.

# Task 4
The current deployment works and correctly DBC decodes data via the function app.

We now wish to enable the user to receive a notification when an event happens in the data. You can see how this is handled in the Google Cloud case by looking at the google/mdftoparquet/ and in particular the google/mdftoparquet/modules/monitoring/ folder. Here, we use google's monitoring functionality to check if the info logs from the function invocation include a specific payload ("NEW EVENT"). If so, we consider this an event that triggers the deployed alert functionality and notifies the user by email.

We wish to implement a similar concept within Azure. As part of this, you've previously created a suggested plan for implementation. See AGENT_PLAN.md for details.

Based on this plan (and the details above), please implement the solution.

Note: The monitoring/alerting terraform stack should be deployed in a modules/ folder called monitoring/ to match the structure of the other stack (we did some refactoring vs. previous deployments, so the AGENT_PLAN.md may be a bit outdated).