# Exercise 5 - Development workflow
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
i.e. to open a problem
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event.sh
```
i.e. to close a problem. Copy the file keptn_event.sh as keptn_event_finished.sh
```(bash)
cp /home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event.sh /home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event_finished.sh
```
and replace the last part of the event `triggered` for `finished`. 
```(bash)
/home/$shell_user/perform-2022-hot-aiops/exercises/scripts/keptn_event_finished.sh 
```
Sample of the final data payload
```
'{
       "specversion":"1.0",
       "source":"manual",
       "id":"100",
       "time":"",
       "contenttype":"application/json",
       "type": "sh.keptn.event.production.auto_healing_disk.finished",
       "data": {
           "State":"closed",
           "ProblemID":"100",
           "PID":"100",
           "ProblemTitle":"Resource problem demo",
           "ProblemURL":"demo.live",
           "ProblemDetails":"", 
           "Tags":"demo",
            "ImpactedEntities":"",
            "ImpactedEntity":"",
            "project":"easytravel",
            "stage":"production",
           "service":"allproblems"
           }
        }' 
```
In order to test the keptn webhook service you can create a mock subscription using services like https://webhook.site/. This would help you validate the contents of the payload and troubleshoot any content problems.

### Remediation script/service 
This part depends on the actual remediation action. It can be a simple script execution or a complex integration with a third party service. For the previous part of the lab we use AWX, you can test it by running manually the remediation script from the AWX UI.

### Quality gate evaluation
This is another full HOT session that you can learn more about. In order to keep this session focus you can use a simple SLI definition without SLO objetives, this way all the evaluations would return ok.

If you want to test a failure you can always use a SLO file with fake objectives.



