
curl -s -X POST \
          "$KEPTN_ENDPOINT/v1/event" \
   --header "x-token: $KEPTN_API_TOKEN" \
   --header 'Content-Type: application/cloudevents+json' \
   --data '{"specversion":"1.0","source":"dynatrace","id":"100","time":"","contenttype":"application/json","type": "sh.keptn.event.production.auto_healing_memory.triggered","data": {"State":"open","ProblemID":"100","PID":"100","ProblemTitle":"Demo degradation","ProblemURL":"demo.problem.com","ProblemDetails":"", "Tags":"demo", "ImpactedEntities":"","ImpactedEntity":"","project":"easytravel","stage":"production","service":"allproblems"}}"' 
 
