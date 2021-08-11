az extension add -n azure-cli-ml -y
az ml computetarget attach aks -n myaks -i "$AKS_ID" -g "$RG" -w "$WORKSPACE_NAME"
