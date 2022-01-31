
#parameters
source="dynatrace"
dataEvent=

curl -s -X POST \
          "$KEPTN_ENDPOINT/v1/event" \
   --header "x-token: $KEPTN_API_TOKEN" \
   --header 'Content-Type: application/cloudevents+json' \
   --data '{
       "specversion":"1.0",
       "source":"manual",
       "type": "sh.keptn.event.clean_disk.finished",
       "datacontenttype": "application/json",
       "triggeredid":"'$1'", 
       "shkeptncontext":"'$2'",
       "data": {
           "project":"easytravel",
           "stage":"production-disk",
           "service":"allproblems",
           "status": "succeeded",
           "message": "manual remediation completed",
           "result":"'$3'",
           "action": {
             "status":"succeeded", 
             "result":"'$3'" 
           }
        }
      }'