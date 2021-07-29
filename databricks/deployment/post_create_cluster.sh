#!/usr/bin/env bash
# Databricks cluster config variables
# DATABRICKS_CLUSTER_NAME="test-cluster-01"
# DATABRICKS_SPARK_VERSION="7.3.x-scala2.12"
# DATABRICKS_NODE_TYPE="Standard_D3_v2"
# DATABRICKS_NUM_WORKERS=3
# DATABRICKS_AUTO_TERMINATE_MINUTES=30
# DATABRICKS_SPARK_CONF='{
#         "spark.databricks.delta.preview.enabled": "true",
#         "spark.eventLog.unknownRecord.maxSize":"16m"
#     }'
# DATABRICKS_INIT_CONFIG='{
#         "dbfs": {
#             "destination": "dbfs:/databricks/init/capture_log_metrics.sh"
#         }
#     }'
# DATABRICKS_ENV_VARS='{
#         "LOG_ANALYTICS_WORKSPACE_ID": "{{secrets/'$DATABRICKS_SECRET_SCOPE'/LogAWkspId}}",
#         "LOG_ANALYTICS_WORKSPACE_KEY": "{{secrets/'$DATABRICKS_SECRET_SCOPE'/LogAWkspkey}}"
#     }'
# DATABRICKS_CLUSTER_LOG='{
#     "dbfs": {
#       "destination": "dbfs:/logs"
#     }
# }'

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
