# Exercise 6 (optional) - Implement a remediation pipeline

Use the concepts from the previous exercise and implement a remediation pipeline by using the already defined workflow named `"production-disk"`. 
```(yaml)
    - name: "production-disk"
      sequences:
      - name: "auto_healing_disk"
        tasks:
        - name: clean_disk
        - name: evaluation
          triggeredAfter: "2m"
          properties:
            timeframe: "2m"
      - name: "auto_healing_disk_failed"
        triggeredon: auto_healing_disk result = "fail"
        tasks:
        - name: escalate_human
```
Key points to implement:

1. Configure an alerting profile and problem remediation in Dynatrace to send a `auto_healing_disk` as problem type. (Check the already configure alerting profile and problem remediation for reference).
1. Configure a webhook in Keptn to be triggered on `clean_disk` and send a message to a mock webhook. (you can use services such as https://webhook.site/ or https://pipedream.com/)
1. Use the script `keptn_event_finished.sh` to send a `clean_disk` finished event. The action block should return a `succeeded` status with `failed` as a result to simulate a call to a service that wasn't able to remediate the problem.
    ```
    "action": {
                "status":"succeeded", //could also be errored or succeeded
                "result":"failed", //could also be failed or pass
            },
    ```
1. Implement a quality gate to evaluate the health of the application. Since there is no running application for this example, we will reuse the previous app with an impossible SLO to always get a failure as a result. Execute the following to add the file and configure the project
```
keptn add-resource --project=easytravel --stage=production-disk --service=allproblems --resource=/home/$shell_user/perform-2022-hot-aiops/install/keptn/slo-unreal.yaml --resourceUri=slo.yaml
keptn configure monitoring dynatrace --project=easytravel
```
To test the evaluation run
```
keptn trigger evaluation --project=easytravel --stage=production-disk --service=allproblems --timeframe=60m --labels=executedBy=manual
```

1. Configure a webhook in Keptn to be trigger on `escalate_human` and send a message to a mock webhook. (https://webhook.site/ or https://pipedream.com/)
1. Trigger the entire workflow by sending a fake problem using Dynatrace API (create_problem.sh) script.







