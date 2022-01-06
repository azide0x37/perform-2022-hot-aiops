#!/usr/bin/env bash
################################
#      SETUP 1                 #
################################
echo "-------------SETUP 1 --------------------"
domain="nip.io"
USER="ace"
DT_CREATE_ENV_TOKENS=true
echo DT_ENV_URL=$DT_ENV_URL
echo DT_CLUSTER_TOKEN=$DT_CLUSTER_TOKEN
echo shell_user=$shell_user
echo shell_password=$shell_password

#################################
# Create Dynatrace Tokens       #
#################################

DT_CREATE_ENV_TOKENS=${DT_CREATE_ENV_TOKENS:="false"}
echo "Create Dynatrace Tokens? : $DT_CREATE_ENV_TOKENS"

if [ "$DT_CREATE_ENV_TOKENS" != "false" ]; then
    printf "Creating PAAS Token for Dynatrace Environment ${DT_ENV_URL}\n\n"

    paas_token_body='{
                        "scopes": [
                            "InstallerDownload"
                        ],
                        "name": "hot-aiops-paas"
                    }'

    DT_PAAS_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_ENV_URL}/api/v2/apiTokens" \
    --header "Authorization: Api-Token $DT_CLUSTER_TOKEN" \
    --header "Content-Type: application/json" \
    --data-raw "${paas_token_body}")
    DT_PAAS_TOKEN=$(echo $DT_PAAS_TOKEN_RESPONSE | jq -r '.token' )

    printf "Creating API Token for Dynatrace Environment ${DT_ENV_URL}\n\n"

    api_token_body='{
                    "scopes": [
                        "DataExport", "PluginUpload", "DcrumIntegration", "AdvancedSyntheticIntegration", "ExternalSyntheticIntegration", 
                        "LogExport", "ReadConfig", "WriteConfig", "DTAQLAccess", "UserSessionAnonymization", "DataPrivacy", "CaptureRequestData", 
                        "Davis", "DssFileManagement", "RumJavaScriptTagManagement", "TenantTokenManagement", "ActiveGateCertManagement", "RestRequestForwarding", 
                        "ReadSyntheticData", "DataImport", "auditLogs.read", "metrics.read", "metrics.write", "entities.read", "entities.write", "problems.read", 
                        "problems.write", "networkZones.read", "networkZones.write", "activeGates.read", "activeGates.write", "credentialVault.read", "credentialVault.write", 
                        "extensions.read", "extensions.write", "extensionConfigurations.read", "extensionConfigurations.write", "extensionEnvironment.read", "extensionEnvironment.write", 
                        "metrics.ingest", "securityProblems.read", "securityProblems.write", "syntheticLocations.read", "syntheticLocations.write", "settings.read", "settings.write", 
                        "tenantTokenRotation.write", "slo.read", "slo.write", "releases.read", "apiTokens.read", "apiTokens.write", "logs.read", "logs.ingest"
                    ],
                    "name": "hot-aiops-api-token"
                    }'

    DT_API_TOKEN_RESPONSE=$(curl -k -s --location --request POST "${DT_ENV_URL}/api/v2/apiTokens" \
    --header "Authorization: Api-Token $DT_CLUSTER_TOKEN" \
    --header "Content-Type: application/json" \
    --data-raw "${api_token_body}")
    DT_API_TOKEN=$(echo $DT_API_TOKEN_RESPONSE | jq -r '.token' )
fi

##############################
# Retrieve Hostname and IP   #
##############################

# Get the IP and hostname depending on the cloud provider
IS_AMAZON=$(curl -o /dev/null -s -w "%{http_code}\n" http://169.254.169.254/latest/meta-data/public-ipv4)
if [ $IS_AMAZON -eq 200 ]; then
    echo "This is an Amazon EC2 instance"
    VM_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)
else
    IS_GCP=$(curl -o /dev/null -s -w "%{http_code}\n" -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    if [ $IS_GCP -eq 200 ]; then
        echo "This is a GCP instance"
        VM_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
        HOSTNAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/hostname)
    fi
fi

echo "Virtual machine IP: $VM_IP"
echo "Virtual machine Hostname: $HOSTNAME"
ingress_domain="$VM_IP.$domain"
PRIVATE_IP=$(hostname -i)
echo "Ingress domain: $ingress_domain"

############   EXPORT VARIABLES   ###########
echo "export variables"
export DT_API_TOKEN=$DT_API_TOKEN
export DT_PAAS_TOKEN=$DT_PAAS_TOKEN
export VM_IP=$VM_IP
export HOSTNAME=$HOSTNAME
export ingress_domain=$ingress_domain
export PRIVATE_IP=$PRIVATE_IP

###########  Part 2  ##############
./perform-2022-hot-aiops/install/setup-2.sh