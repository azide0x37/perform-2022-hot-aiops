################################
#      SETUP 9                 #
################################
echo "############### SETUP 9 - Webhook automation ###########################"
#########################################
#  VARIABLES                            #
#########################################
URL_UNIFORM="$KEPTN_ENDPOINT/controlPlane/v1/uniform/registration"
UNIFORM_ID="none"
URL_TEST="https://webhook.site/e87b3e69-f972-44c8-aecd-60e0648d1bba"
#get Uniforms
UNIFORM_RESPONSE=$(curl -k -s --location --request GET $URL_UNIFORM \
    -H "accept: application/json" \
    -H "x-token: $KEPTN_API_TOKEN")
    
## Looks for the uniform ID for webhook
 for row in $(echo "$UNIFORM_RESPONSE" | jq -r '.[] | @base64'); do
  _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
  RES=$(echo $(_jq '.name'))
  if [  "$RES" = "webhook-service" ]; then
    echo "Uniform id"
    UNIFORM_ID=$(echo $(_jq '.id'))
    echo $UNIFORM_ID
  fi
done

##Adds a new webhook 
 pbody='{
  "subscription": {
    "event": "sh.keptn.event.escalate_human.triggered",
    "parameters": [],
    "filter": {
      "projects": [
        "easytravel"
      ],
      "stages": [],
      "services": []
    }
  },
  "webhookConfig": {
    "type": "sh.keptn.event.escalate_human.triggered",
    "method": "POST",
    "url": "$URL_TEST",
    "payload": "",
    "header": [],
    "sendFinished": false,
    "proxy": "",
    "filter": {
      "projects": [
        "easytravel"
      ],
      "stages": [],
      "services": []
    }
  }
}'
URL_WEBHOOK="$KEPTN_URL/api/controlPlane/v1/uniform/registration/$UNIFORM_ID/subscription"

WEBHOOK_RESPONSE=$(curl -k -s --location --request POST $URL_WEBHOOK \
    -H "accept: application/json" \
    -H "x-token: $KEPTN_TOKEN" \
    --data-raw "$pbody")
echo "response webhook"
echo "$WEBHOOK_RESPONSE"



if [ "$PROGRESS_CONTROL" -gt "10" ]; then
/home/$shell_user/perform-2022-hot-aiops/install/setup-10.sh
fi