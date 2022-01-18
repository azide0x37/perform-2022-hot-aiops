
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
       "type": "sh.keptn.event.production.auto_healing_disk.triggered",
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
            "stage":"production",
           "service":"allproblems"
           }
        }"' 

