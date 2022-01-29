
#parameters
source="dynatrace"

curl -s -X POST \
          "$KEPTN_ENDPOINT/v1/event" \
   --header "x-token: $KEPTN_API_TOKEN" \
   --header 'Content-Type: application/cloudevents+json' \
   --data '{
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