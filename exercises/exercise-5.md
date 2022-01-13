# Exercise 5 - Development workflow
The goal for this second part of the lab is to learn how to develop new remediation workflows by ***testing each part of the process independently*** and then assembling everything into a single workflow.

## Step 1 - Identify the components

The solution has the following components:

- Dynatrace problem detection
- Keptn remediation workflow
- Keptn webhook service
- Remediation script/service 
- Quality gate evaluation
- Escalation script/service

In order to be able to develop and iterate multiple times we need a way to test each component isolated from the rest of the architecture. 

### Dynatrace problem detection 
This is probably the most difficult component to test since it would require an application with problems that can be trigger manually. Fortunately, at Dynatrace we have Easytravel (https://confluence.dynatrace.com/community/display/DL/easyTravel).

You can also develop your own test application based on techical articles depending on the programming language and the type of problem to simulate i.e. (https://michaelscodingspot.com/ways-to-cause-memory-leaks-in-dotnet/)

### Keptn remediation workflow
Instead of waiting for a problem to be detected by Dynatrace to test your integration you can use the keptn API to send fake problem events to test your workflow.

i.e. 

### Keptn webhook service

### Remediation script/service 

### Quality gate evaluation

### Escalation script/service

