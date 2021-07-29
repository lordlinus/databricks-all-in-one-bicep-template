#!/usr/bin/env bash

pat_token_config=$(jq -n -c \
    --arg ls "$PAT_LIFETIME" \
    --arg co "Example Token" \
    '{lifetime_seconds: ($ls|tonumber),
                    comment: $co
                    }')

# Databricks Auth headers
adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

# Create Auth header for Databricks
authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$adbId"

d_curl() {
    local db_url=${1:?Must provide an argument}
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" $db_url
}

pat_token_response=$(echo "$pat_token_config" | d_curl "https://${adbWorkspaceUrl}/api/2.0/token/create")
PAT_TOKEN=$(echo $pat_token_response | jq -r '.token_value')
echo ${PAT_TOKEN}
AZ_SCRIPTS_OUTPUT_PATH=${PAT_TOKEN}