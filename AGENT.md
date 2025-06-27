# Context
This repository contains terraform stacks and deployment scripts for deploying resources in Azure via the 'bash' cloud shell environment. See the README.md for details and go through all files in mdftoparquet/ as well as teh deploy_mdftoparquet.sh.

The mdftoparquet folder contains a deployment stack for deploying an Azure function. The user uploads a zip with the function contents into the input container. The deployment then fetches this and deploys it in an Azure Function App. It also deploys an output bucket.

This works currently including the installation of relevant dependencies if we do a clean deployent for the first time. However, if we try to deploy again with a new function zip (with a new name), the expected result would be that the function in the Function App would get updated accordingly. 

This was the case previous in the info/main_old.tf script. But with the current script in the mdftoparquet folder, this is not the case. The problem with the old method was that it was deploying the function correctly - but it did not install the requirements.txt dependencies properly, causing issues when importing various libraries.



# Task 3
Review the mdftoparquet/ and the info/main_old.tf. 

Determine why the Azure Function App function is not properly getting updated in the mdftoparquet/ deployment when the user provides a new function zip. This may be related to how the function is temporarily being stored/cached as part of the deployment and dependency installation, i.e. I'm guessing we somehow keep deploying the same function over-and-over, rather than actually updating it with the new zip being provided by the user.

Update the deployment to still use the zip deployment logic (so as to ensure dependencies are installed during deployment from the requirements.txt) - but make sure that the deployment gets updated with the contents of the zip file being provided by the user via the input --zip argument (stored in the input container).

