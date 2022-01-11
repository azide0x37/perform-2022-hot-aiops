# Exercise 3 - Setup the remediation use case

 1. From your console run ```/home/$shell_user/perform-2022-hot-aiops/install/setup-7.sh ```.
 This script will execute the following:
 - Create a git repository to store the EasyTravel remediation project
 - Configure a new Keptn project called easytravel with a remediation workflow.
 Take a look at the ```shipyard.yaml``` file in the gitea repository. (master branch)
 - Setup Dynatrace problem notification to send the problems to Keptn by using [Dynatrace as Code] (https://dynatrace-oss.github.io/dynatrace-monitoring-as-code)

 2. From your console run ```/home/$shell_user/perform-2022-hot-aiops/install/setup-8.sh ```.
 This script will execute the following:
 - Generate a template to create the webhook in keptn (we will use this to manually get into the UI and create the webhook)

3. Create the webhook in Keptn.
Get into the keptn bridge and select the easytravel project. 
Select the webhook menu from the left bar 
Select the webhook service and add a subscription
![webhook](./images/webhook-service.png)

5. Fill the form with the values from step 2
![webhook-content](./images/webhook-content.png)

4.(Temporal) Fix the webhook file. 

[Next](./exercise-4.md)