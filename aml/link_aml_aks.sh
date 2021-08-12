#/bin/bash -e
az extension add -n azure-cli-ml -y
json=$(az ml computetarget attach aks -n myaks -i "$AKS_ID" -g "$RG" -w "$WORKSPACE_NAME")
echo "$json" >$AZ_SCRIPTS_OUTPUT_PATH
