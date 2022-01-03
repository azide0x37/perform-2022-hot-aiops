### 2. Trigger a memory leak problem
Get into AWX (you can use the dashboard to find the link to AWX) and locate the template to trigger a new memory leak (click on the rocket icon on the right) [mleak](./memory-leak.png)
This will use the EasyTravel API to trigger a memory leak that will be detected in Dynatrace after a few mins and will start the remediation process.

### 3. Remediation process
1. Dynatrace will detect a high memory consumption from the easytravel application.
[memory-exhausted](./dyna-memory.png)
2. Dynatrace will send a problem notification to Keptn. (can take a few mins to trigger)
3. Keptn will check for that service the remediation file that was specified.

