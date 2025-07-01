# Context
Read the README.md and the mdftoparquet/ folder and the deploy_mdftoparquet.sh in full.

This part of the repo deploys an output container and an Azure Function. This enables automatic DBC decoding of data and alerting via email if a specific 'NEW EVENT' payload is observed in the logs from the function.

The problem with this is that we're using Application Insights, which is fairly costly. I'm trying to minimize costs. As part of this, I would like to attempt switching the deployment to still achieve email alerts - but in a more serverless manner, where we do not have any significant costs when the deployment is just 'idling'.

Below is an initial suggestion for a plan on how this can be implemented. Please review the plan and consider if it is suitable. Then proceed to updating the mdftoparquet/ terraform stack with the relevant changes, as well as the deploy_mdftoparquet.sh script.

In addition, I have put the Azure function in info/mdf-to-parquet-azure-function-v3.1.5. Please update the modules/cloud_functions.py to accomodate the necessary changes required for the shift to the new infrastructure. 

# Task 1
1) Update the Azure Function to publish the event message to the queue (in addition to communicating it via logger.warning as today)
2) Re-use the logic app we already deploy in the mdftoparquet/stack - but trigger it based on the queue message instead of Application Insights
3) Remove the Application Insights deployment from the stack 

