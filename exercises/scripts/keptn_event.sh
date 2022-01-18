
#parameters
source="dynatrace"
id="100"
state="open"
problemTitle="Demo degradation"
problemUrl="demo.problem.com"
if [ $1 -eq "OPEN"]; then
status="triggered"
event="sh.keptn.event.production.auto_healing_disk.$status"

fi

if [$2 -eq "CLOSED"]; then
status="finished"
event="sh.keptn.event.production.auto_healing_disk.$status"
fi
curl -s -X POST \
          "$KEPTN_ENDPOINT/v1/event" \
   --header "x-token: $KEPTN_API_TOKEN" \
   --header 'Content-Type: application/cloudevents+json' \
   --data '{
       "specversion":"1.0",
       "source":$source,
       "id":$id,
       "time":"",
       "contenttype":"application/json",
       "type": $event,
       "data": {
           "State":$state,
           "ProblemID":$id,
           "PID":$id,"ProblemTitle":$problemTitle,"ProblemURL":$problemUrl,"ProblemDetails":"", "Tags":"demo", "ImpactedEntities":"","ImpactedEntity":"","project":"easytravel","stage":"production","service":"allproblems"}}"' 
