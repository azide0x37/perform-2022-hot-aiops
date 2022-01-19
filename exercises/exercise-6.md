# Exercise 6 (optional) - Implement a remediation pipeline

Use the concepts from the previous exercise and implement a remediation pipeline.
Key points:

1. Configure an alerting profile and problem remediation to send a `auto_healing_disk` as problem type.
1. Configure a webhook in Keptn to be trigger on `clean_disk` and send a message to a mock webhook. (https://webhook.site/ or https://pipedream.com/)
1. Modify the script `keptn_event_finished.sh` to send a clean_disk finished event when executed with a failure as result.
1. Implement a quality gate to evaluate the health of the application. Since there is no running application for this example, you can include an SLI without any objectives.
1. Configure a webhook in Keptn to be trigger on `escalate_human` and send a message to a mock webhook. (https://webhook.site/ or https://pipedream.com/)
1. Trigger the entire workflow by sending a fake problem using Dynatrace API (create_problem.sh) script.





