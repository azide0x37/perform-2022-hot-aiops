
#parameters
source="dynatrace"

curl -s -X POST \
          "$KEPTN_ENDPOINT/v1/event" \
   --header "x-token: $KEPTN_API_TOKEN" \
   --header 'Content-Type: application/cloudevents+json' \
   --data '{
       "specversion":"1.0",
       "source":"manual",
       "id":"100",
       "time":"",
       "contenttype":"application/json",
       "type": "sh.keptn.event.production-disk.auto_healing_disk.triggered",
       "data": {
           "State":"open",
           "ProblemID":"100",
           "PID":"100",
           "ProblemTitle":"Resource problem demo",
           "ProblemURL":"demo.live",
           "ProblemDetails":"", 
           "Tags":"demo",
            "ImpactedEntities":"",
            "ImpactedEntity":"",
            "project":"easytravel",
            "stage":"production-disk",
           "service":"allproblems"
           }
        }' 

# Sample data from a real problem 

# "data": {"State":"RESOLVED","ProblemID":"P-22011","PID":"-5988270214550055152_1642566000000V2","ProblemTitle":"Memory resources exhausted","ProblemURL":"https://ymg648.managed-sprint.dynalabs.io/e/4dacea76-2af5-4fc6-a94c-a17c12980884/#problems/problemdetails;pid=-5988270214550055152_1642566000000V2","ProblemDetails":{"id":"-5988270214550055152_1642566000000V2","startTime":1642566060000,"endTime":1642566360000,"displayName":"P-22011","impactLevel":"INFRASTRUCTURE","status":"CLOSED","severityLevel":"RESOURCE_CONTENTION","commentCount":0,"tagsOfAffectedEntities":[],"rankedEvents":[{"startTime":1642566000000,"endTime":1642566660000,"entityId":"PROCESS_GROUP_INSTANCE-E9567698467953B4","entityName":"com.dynatrace.easytravel.business.backend.jar easytravel-*-x*","severityLevel":"RESOURCE_CONTENTION","impactLevel":"INFRASTRUCTURE","eventType":"MEMORY_RESOURCES_EXHAUSTED","status":"CLOSED","severities":[],"isRootCause":true}],"rankedImpacts":[{"entityId":"PROCESS_GROUP_INSTANCE-E9567698467953B4","entityName":"com.dynatrace.easytravel.business.backend.jar easytravel-*-x*","severityLevel":"RESOURCE_CONTENTION","impactLevel":"INFRASTRUCTURE","eventType":"MEMORY_RESOURCES_EXHAUSTED"}],"affectedCounts":{"INFRASTRUCTURE":0,"SERVICE":0,"APPLICATION":0,"ENVIRONMENT":0},"recoveredCounts":{"INFRASTRUCTURE":1,"SERVICE":0,"APPLICATION":0,"ENVIRONMENT":0},"hasRootCause":true},"Tags":"","ImpactedEntities":[{"type":"PROCESS_GROUP_INSTANCE","name":"com.dynatrace.easytravel.business.backend.jar easytravel-*-x*","entity":"PROCESS_GROUP_INSTANCE-E9567698467953B4"}],"ImpactedEntity":"Memory resources exhausted on Process com.dynatrace.easytravel.business.backend.jar easytravel-*-x*","project":"easytravel","stage":"production-disk","service":"allproblems"}

# curl -s -X POST \
#           "$KEPTN_ENDPOINT/v1/event" \
#    --header "x-token: $KEPTN_API_TOKEN" \
#    --header 'Content-Type: application/cloudevents+json' \
#    --data '{
#        "specversion":"1.0",
#        "source":"manual",
#        "type": "sh.keptn.event.clean_disk.finished",
#        "datacontenttype": "application/json",
#        "triggeredid":"0ee31b51-7902-426d-87ae-f58fb0617bec", 
#        "shkeptncontext":"9c229691-0ec1-4e06-a306-9240488b1403",
#        "data": {
#            "project":"easytravel",
#            "stage":"production-disk",
#            "service":"allproblems",
#            "status": "succeeded",
#            "message": "manual remediation completed",
#            "result":"pass",
#            "action": {
#              "status":"succeeded", 
#              "result":"pass" 
#            }
#            }
#         }'  