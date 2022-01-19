# Exercise 5 - Development workflow

*** Disclaimer: Keptn with Webhooks is in Beta as January 14th.
The goal for this second part of the lab is to learn how to develop new remediation workflows by ***testing each part of the process independently*** and then assembling everything into a single workflow.

## Step 1 - Identify the components

The solution has the following components:

1. Dynatrace problem detection
1. Keptn remediation workflow
1. Remediation script/service 
1. Quality gate evaluation

In order to be able to develop and iterate multiple times we need a way to test each component isolated from the rest of the architecture. 

### Dynatrace problem detection 
This is probably the most difficult component to test since it would require an application with problems that can be trigger manually. Fortunately, at Dynatrace we have Easytravel (https://confluence.dynatrace.com/community/display/DL/easyTravel).

You can also develop your own test application based on techical articles depending on the programming language and the type of problem to simulate i.e. (https://michaelscodingspot.com/ways-to-cause-memory-leaks-in-dotnet/)

Another option would be to use Dynatrace API to send a custom alert https://www.dynatrace.com/support/help/how-to-use-dynatrace/problem-detection-and-analysis/basic-concepts/event-types/custom-alerts
https://www.dynatrace.com/support/help/dynatrace-api/environment-api/events-v2/post-event
i.e. 
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/simulate-problem.sh "Critical Performance Issue" PERFORMANCE_EVENT
```

### Keptn remediation workflow
Instead of waiting for a problem to be detected by Dynatrace to test your integration you can use the keptn API to send fake problem events to test your workflow.
1. To open a problem modify:
```(bash)
nano /home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event.sh
```
and change the line that says ` "stage":"production"` to `"stage":"production-disk"` and event type from `sh.keptn.event.production` to `sh.keptn.event.production-disk`.

Save the changes and then run
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event.sh
```

2. To close a problem. Copy the file keptn_event.sh as keptn_event_finished.sh
```(bash)
cp /home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event.sh /home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event_finished.sh
```
Replace the data payload with the following content 
```
'{
       "specversion":"1.0",
       "source":"manual",
       "type": "sh.keptn.event.clean_disk.finished",
       "datacontenttype": "application/json",
       "triggeredid":"0ee31b51-7902-426d-87ae-f58fb0617bec", 
       "shkeptncontext":"9c229691-0ec1-4e06-a306-9240488b1403",
       "data": {
           "project":"easytravel",
           "stage":"production-disk",
           "service":"allproblems",
           "status": "succeeded",
           "message": "manual remediation completed",
           "result":"pass",
           "action": {
             "status":"succeeded", 
             "result":"pass" 
           }
           }
        }' 
```
Then replace the values for this fields
```
 "action": {
             "status":"succeeded", //could also be errored or succeeded
             "result":"pass", //could also be failed or pass
           },
           "triggeredid":"7a119f55-4e64-47df-8d10-b68041118d7f", //check this id in the keptn UI
           "shkeptncontext":"54d0d7ca-2109-48ed-aba3-69ebbf62ce20" //update this with the keptn context returned in the initial trigger
```

And execute the event
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event_finished.sh 
```

In order to test the keptn webhook service you can create a mock subscription using services like https://webhook.site/ or https://pipedream.com/. This would help you validate the contents of the payload and troubleshoot any content problems.

### Remediation script/service 
This part depends on the actual remediation action. It can be a simple script execution or a complex integration with a third party service. For the previous part of the lab we use AWX, you can test it by running manually the remediation script from the AWX UI.

### Quality gate evaluation
This is another full HOT session that you can learn more about. In order to keep this session focus you can use a simple SLI definition without SLO objetives, this way all the evaluations would return ok.

If you want to test a failure you can always use a SLO file with fake objectives.



