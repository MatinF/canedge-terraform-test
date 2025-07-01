# Context
Read the README.md and the mdftoparquet/ folder and the deploy_mdftoparquet.sh in full.

This part of the repo deploys an output container and an Azure Function. This enables automatic DBC decoding of data and alerting via email if a specific 'NEW EVENT' payload is observed in the logs from the function. See also info/event-alert.png for how the deployed setup looks.

The setup works fine - but it is costly because it queries my logs constantly, adding a fixed 1.5$ cost per month, which is suboptimal. I want a solution that practically costs nothing when the function is not invoked (less than 0.1$/month)

My thinking is that you can set up a storage queue that will be triggered from within the Azure Function. In info/queue-test/, you can see the current azure function that supports this within the modules/cloud_functions.py. This will publish to the queue when an event happens. 


# Task 1
1) Update the Azure Function to add a storage queue that can be triggered by the Function. For inspiration, see info/inspiration/
2) Re-use the logic app we already deploy in the mdftoparquet/stack - but trigger it based on the queue message instead of Application Insights
3) Remove the Application Insights deployment from the stack 