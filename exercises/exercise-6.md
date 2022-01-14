# Exercise 6 - Implement a remediation pipeline

Use the concepts from the previous exercise and implement a remediation pipeline.

1. To trigger a problem in dynatrace use 
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/simulate-problem.sh "Critical Performance Issue" PERFORMANCE_EVENT
```
2. Configure the alert profile and problem notification to send a notification to Cloud Automation. (you can copy the same info as the previous exercise)





## Add second remediation step
Add a new remedation webhook and a new quality gate evaluation to measure the quality of the service after the execution.
[Next](./exercise-6.md)


You can use [https://webhook.site/](https://webhook.site/) to receive the webhook request and curl or postman to send the remediation end event

