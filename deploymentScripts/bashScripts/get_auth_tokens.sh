adb_global_token=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output json | jq -r .accessToken)
azure_api_token=$(az account get-access-token --resource https://management.core.windows.net/ --output json | jq -r .accessToken)

output=$(jq -n -c \
    --arg agt "$adb_global_token" \
    --arg aat "$azure_api_token" \
    '{adbGlobalToken: $agt, azureApiToken: $aat}')

echo $output > $AZ_SCRIPTS_OUTPUT_PATH