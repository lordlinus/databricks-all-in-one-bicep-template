#!/usr/bin/env bash

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

createSecretScopePayload="{
        \"scope\": \"$DATABRICKS_SECRET_SCOPE\",
        \"scope_backend_type\": \"AZURE_KEYVAULT\",
        \"backend_azure_keyvault\":{\"resource_id\": \"$AKV_ID\",\"dns_name\": \"$AKV_URI\"},
        \"initial_manage_principal\": \"users\"
    }"
echo $createSecretScopePayload | d_curl "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/delete"
echo "Create ADB secret scope backed by Key Vault"
echo $createSecretScopePayload | d_curl "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/create"