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


echo "Upload init script to /databricks/init/capture_log_metrics.sh"
curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
    https://${adbWorkspaceUrl}/api/2.0/dbfs/put \
    --form contents=@init_scripts/capture_log_metrics.sh \
    --form path="/databricks/init/capture_log_metrics.sh" \
    --form overwrite=true

echo "Upload Sample notebooks"
for notebook in notebooks/*.ipynb; do
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
for jar_file in jars/*.jar; do
    filename=$(basename $jar_file)
    echo "Upload $jar_file file to DBFS path"
    curl -sS -X POST -H "$authHeader" -H "$adbSPMgmtToken" -H "$adbResourceId" \
        https://${adbWorkspaceUrl}/api/2.0/dbfs/put \
        --form filedata=@"$jar_file" \
        --form path="/FileStore/jars/$filename" \
        --form overwrite=true
done

