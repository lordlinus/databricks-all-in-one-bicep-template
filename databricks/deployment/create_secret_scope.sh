#/bin/bash -e
secret_scope_payload=$(cat << EOF | envsubst | jq -c
{
    "scope": "${ADB_SECRET_SCOPE_NAME}",
    "scope_backend_type": "AZURE_KEYVAULT",
    "backend_azure_keyvault":{"resource_id": "${AKV_ID}","dns_name": "${AKV_URI}"},
    "initial_manage_principal": "users"
}
EOF
)
echo "$secret_scope_payload" >> "$AZ_SCRIPTS_OUTPUT_PATH"

adbGlobalToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azureApiToken=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

authHeader="Authorization: Bearer $adbGlobalToken"
adbSPMgmtToken="X-Databricks-Azure-SP-Management-Token:$azureApiToken"
adbResourceId="X-Databricks-Azure-Workspace-Resource-Id:$ADB_WORKSPACE_ID"

echo "Delete ADB secret scope if already exists"
j=$(echo $secret_scope_payload | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/secrets/scopes/delete")

echo "Create ADB secret scope backed by Key Vault"
json=$(echo $secret_scope_payload | curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" --data-binary "@-" "https://${ADB_WORKSPACE_URL}/api/2.0/secrets/scopes/create")

# echo "$json" > "$AZ_SCRIPTS_OUTPUT_PATH"
echo "$json" >> "$AZ_SCRIPTS_OUTPUT_PATH"
