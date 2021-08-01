#!/usr/bin/env bash

# Get current user objectId
current_user_object_id=$(az ad signed-in-user show --query "objectId" --output tsv)

if [[ -z "$current_user_object_id" ]]; then
    echo "Please login to azure e.g. az login"
    exit 1
fi

unset username
unset password

read -p 'Client PC Username: ' username
while true; do
  read -s -p "Client PC Password: " password
  echo
  read -s -p "Client PC Password (again): " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done
echo "Ok"

echo "Running Bicep Main deployment file"
bicep_output=$(az deployment sub create \
    --location "southeastasia" \
    --template-file main.bicep \
    --parameters @parameters.json \
    --parameters userObjectId=${current_user_object_id} \
    --parameters adminUsername=$username \
    --parameters adminPassword=$password)

if [[ -z "$bicep_output" ]]; then
    echo "Deployment failed, check errors on Azure portal"
    exit 1
fi

echo $bicep_output >output.json # save output
echo "Bicep deployment. Done"

bicep_output=$(<output.json) # To read local output for testing
echo "Configuring services..."

DATABRICKS_SECRET_SCOPE="secret_scope_01"
DATABRICKS_CLUSTER_NAME="test-cluster-01"
DATABRICKS_SPARK_VERSION="7.3.x-scala2.12"
DATABRICKS_NODE_TYPE="Standard_D3_v2"
DATABRICKS_NUM_WORKERS=3
DATABRICKS_AUTO_TERMINATE_MINUTES=30
DATABRICKS_SPARK_CONF='{
        "spark.databricks.delta.preview.enabled": "true",
        "spark.eventLog.unknownRecord.maxSize":"16m"
    }'
DATABRICKS_INIT_CONFIG='{
        "dbfs": {
            "destination": "dbfs:/databricks/init/capture_log_metrics.sh"
        }
    }'
DATABRICKS_ENV_VARS='{
        "LOG_ANALYTICS_WORKSPACE_ID": "{{secrets/'$DATABRICKS_SECRET_SCOPE'/LogAWkspId}}",
        "LOG_ANALYTICS_WORKSPACE_KEY": "{{secrets/'$DATABRICKS_SECRET_SCOPE'/LogAWkspkey}}"
    }'
DATABRICKS_CLUSTER_LOG='{
    "dbfs": {
      "destination": "dbfs:/logs"
    }
}'
pat_token_config="{
    \"lifetime_seconds\": 36000,
    \"comment\": \"this is an example token\"
}"
AZURE_RESOURCE_GROUP_NAME=$(echo $bicep_output | jq -r '.properties.outputs.resourceGroupName.value')
STORAGE_ACCOUNT_NAME=$(echo $bicep_output | jq -r '.properties.outputs.storageAccountName.value')
ADB_WORKSPACE_NAME=$(echo $bicep_output | jq -r '.properties.outputs.adbWorkspaceName.value')
ADB_WORKSPACE_ID=$(echo $bicep_output | jq -r '.properties.outputs.databricksWksp.value')
AKV_NAME=$(echo $bicep_output | jq -r '.properties.outputs.keyVaultName.value')
AKV_ID=$(echo "$bicep_output" | jq -r '.properties.outputs.keyvault_id.value')
AKV_URI=$(echo "$bicep_output" | jq -r '.properties.outputs.keyvault_uri.value')
LOG_ANALYTICS_WKSP_ID=$(echo "$bicep_output" | jq -r '.properties.outputs.logAnalyticsWkspId.value')
LOG_ANALYTICS_WKSP_KEY=$(echo "$bicep_output" | jq -r '.properties.outputs.logAnalyticsprimarySharedKey.value')
EVENT_HUB_ID=$(echo $bicep_output | jq -r '.properties.outputs.eHubNameId.value')
EVENT_HUB_AUTH_ID=$(echo $bicep_output | jq -r '.properties.outputs.eHAuthRulesId.value')
EVENT_HUB_CONN_STRING=$(echo $bicep_output | jq -r '.properties.outputs.eHPConnString.value')

storageAccountKey1=$(echo "$bicep_output" | jq -r '.properties.outputs.storageKey1.value')
storageAccountKey2=$(echo "$bicep_output" | jq -r '.properties.outputs.storageKey2.value')

# Get ADB id and workspaceurl
adbId=$(echo "$bicep_output" | jq -r '.properties.outputs.databricksWksp.value')
adbWorkspaceUrl=$(echo "$bicep_output" | jq -r '.properties.outputs.databricks_workspaceUrl.value')

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

# echo "Adding local IP into ACL while storing SA secrets (before private link config) ...."
az keyvault network-rule add --resource-group "$AZURE_RESOURCE_GROUP_NAME" --name "$AKV_NAME" --ip-address "$(curl -s ifconfig.me)" --output none
echo "Storing loganalytics,storage,eventhub in key vault"
az keyvault secret set -n "LogAWkspId" --vault-name "$AKV_NAME" --value "$LOG_ANALYTICS_WKSP_ID" --output none
az keyvault secret set -n "LogAWkspkey" --vault-name "$AKV_NAME" --value "$LOG_ANALYTICS_WKSP_KEY" --output none
az keyvault secret set -n "StorageAccountKey1" --vault-name "$AKV_NAME" --value "$storageAccountKey1" --output none
az keyvault secret set -n "StorageAccountKey2" --vault-name "$AKV_NAME" --value "$storageAccountKey2" --output none
az keyvault secret set -n "EventHubPK" --vault-name "$AKV_NAME" --value "$EVENT_HUB_CONN_STRING" --output none
echo "Successfully stored secrets"

# Get ADB log categories
adb_logs_types=$(az monitor diagnostic-settings categories list --resource $ADB_WORKSPACE_ID | jq -c '.value[] | {category: .name, enabled:true}' | jq --slurp .)

# Enable monitoring for all the categories
adb_monitoring=$(az monitor diagnostic-settings create \
    --name sparkmonitor \
    --event-hub $EVENT_HUB_ID \
    --event-hub-rule "RootManageSharedAccessKey" \
    --resource $ADB_WORKSPACE_ID \
    --logs "$adb_logs_types")

createSecretScopePayload="{
        \"scope\": \"$DATABRICKS_SECRET_SCOPE\",
        \"scope_backend_type\": \"AZURE_KEYVAULT\",
        \"backend_azure_keyvault\":{\"resource_id\": \"$AKV_ID\",\"dns_name\": \"$AKV_URI\"},
        \"initial_manage_principal\": \"users\"
    }"
echo $createSecretScopePayload | d_curl "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/delete"
echo "Create ADB secret scope backed by Key Vault"
echo $createSecretScopePayload | d_curl "https://${adbWorkspaceUrl}/api/2.0/secrets/scopes/create"
pat_token_response=$(echo "$pat_token_config" | d_curl "https://${adbWorkspaceUrl}/api/2.0/token/create")
PAT_TOKEN=$(echo $pat_token_response | jq -r '.token_value')
echo "PAT Token: ${PAT_TOKEN}"
echo "Storing databricks personal access token in key vault"
az keyvault secret set -n "DBPAT" --vault-name "$AKV_NAME" --value "$PAT_TOKEN" --output none

echo "Upload init script to /databricks/init/capture_log_metrics.sh"
curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
    https://${adbWorkspaceUrl}/api/2.0/dbfs/put \
    --form contents=@databricks/init_scripts/capture_log_metrics.sh \
    --form path="/databricks/init/capture_log_metrics.sh" \
    --form overwrite=true

echo "Upload Sample notebooks"
for notebook in databricks/notebooks/*.ipynb; do
    filename=$(basename $notebook)
    echo "Upload sample notebook $notebook to workspace"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${adbWorkspaceUrl}/api/2.0/workspace/import \
        --form contents=@"$notebook" \
        --form path="/Shared/$filename" \
        --form format=JUPYTER \
        --form language=SCALA \
        --form overwrite=true
done

echo "Upload jar files"
for jar_file in databricks/jars/*.jar; do
    filename=$(basename $jar_file)
    echo "Upload $jar_file file to DBFS path"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${adbWorkspaceUrl}/api/2.0/dbfs/put \
        --form filedata=@"$jar_file" \
        --form path="/FileStore/jars/$filename" \
        --form overwrite=true
done

echo "Create Cluster"
sleep 5
CLUSTER_CREATE_JSON_STRING=$(jq -n -c \
    --arg cn "$DATABRICKS_CLUSTER_NAME" \
    --arg sv "$DATABRICKS_SPARK_VERSION" \
    --arg nt "$DATABRICKS_NODE_TYPE" \
    --arg nw "$DATABRICKS_NUM_WORKERS" \
    --arg spc "$DATABRICKS_SPARK_CONF" \
    --arg at "$DATABRICKS_AUTO_TERMINATE_MINUTES" \
    --arg is "$DATABRICKS_INIT_CONFIG" \
    --arg ev "$DATABRICKS_ENV_VARS" \
    --arg cl "$DATABRICKS_CLUSTER_LOG" \
    '{cluster_name: $cn,
                    spark_version: $sv,
                    node_type_id: $nt,
                    num_workers: ($nw|tonumber),
                    autotermination_minutes: ($at|tonumber),
                    spark_conf: ($spc|fromjson),
                    init_scripts: ($is|fromjson),
                    spark_env_vars: ($ev|fromjson),
                    cluster_log_conf: ($cl|fromjson)
                    }')

cluster_create=$(echo $CLUSTER_CREATE_JSON_STRING | d_curl "https://${adbWorkspaceUrl}/api/2.0/clusters/create")
echo $cluster_create

cluster_id=$(echo $cluster_create | jq -r '.cluster_id')
db_cluster_state=$(curl -sS -X GET -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" -d $cluster_create "https://${adbWorkspaceUrl}/api/2.0/clusters/get")
echo $db_cluster_state

echo "Install Libraries required"
sleep 10 # Need to wait to get the cluster registred
library_config="{
    \"cluster_id\": \"$cluster_id\",
    \"libraries\": [
        {
                \"jar\": \"dbfs:/FileStore/jars/spark-listeners_3.0.1_2.12-1.0.0.jar\"
        },
        {
                \"jar\": \"dbfs:/FileStore/jars/spark-listeners-loganalytics_3.0.1_2.12-1.0.0.jar\"
        },
        {
            \"maven\": {
                \"coordinates\": \"com.databricks.labs:overwatch_2.12:0.4.13\"
            }
        },
        {
            \"maven\": {
                \"coordinates\": \"com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.18\"
            }
        }
    ]
}"

cluster_library_install=$(echo $library_config | d_curl "https://${adbWorkspaceUrl}/api/2.0/libraries/install")
echo $cluster_library_install

echo "Create Overwatch Job"
JOB_CREATE_JSON_STRING=$(jq -n -c \
    --arg ci "$cluster_id" \
    '{name: "overwatch-job",
                    existing_cluster_id: $ci,
                    notebook_task: {
                    "notebook_path": "/Shared/azure_runner_docs_example.ipynb"
                                    }
                    }')
create_notebook_job=$(echo $JOB_CREATE_JSON_STRING | d_curl "https://${adbWorkspaceUrl}/api/2.0/jobs/create")
echo $create_notebook_job

echo "Configuring services done"
