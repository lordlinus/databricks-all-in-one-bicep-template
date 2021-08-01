#!/usr/bin/env bash
# Script to get PAT from Databricks and set in keyvault.

pat_token_config=$(jq -n -c \
    --arg ls "$PAT_LIFETIME" \
    --arg co "Example Token" \
    '{lifetime_seconds: ($ls|tonumber), comment: $co}')

# Create Auth header for Databricks
auth_header="Authorization: Bearer $ADB_GLOBAL_TOKEN"
adb_sp_mgmt_token="X-Databricks-Azure-SP-Management-Token:$AZURE_API_TOKEN"
adb_resource_id="X-Databricks-Azure-Workspace-Resource-Id:$ADB_ID"

d_curl() {
    local db_url=${1:?Must provide an argument}
    curl -sS -X POST -H "$auth_header" -H "$adb_sp_mgmt_token" -H "$adb_resource_id" --data-binary "@-" $db_url
}

pat_token_response=$(echo "$pat_token_config" | d_curl "https://${ADB_WORKSPACE_URL}/api/2.0/token/create")
pat_token=$(echo $pat_token_response | jq -r '.token_value')

az keyvault secret set -n "DBPAT" --vault-name "$AKV_NAME" --value "$pat_token" --output none