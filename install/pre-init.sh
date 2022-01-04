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


 sudo DT_ENV_URL=$DT_ENV_URL DT_API_TOKEN=$DT_API_TOKEN DT_PAAS_TOKEN=$DT_PAAS_TOKEN shell_user=$shell_user shell_password=$shell_password /tmp/init.sh