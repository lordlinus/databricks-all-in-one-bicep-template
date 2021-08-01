#!/usr/bin/env bash

unset username
unset password

read -p 'Client PC Username: ' username
prompt="Client PC Password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    password+="$char"
done
echo
echo "Ok"

echo "Running Bicep Main deployment file"
bicep_output=$(az deployment sub create \
    --location "southeastasia" \
    --template-file main.bicep \
    --parameters @parameters.json \
    --parameters adminUsername=$username \
    --parameters adminPassword=$password)

if [[ -z "$bicep_output" ]]; then
    echo "Deployment failed, check errors on Azure portal"
    exit 1
fi

echo "$bicep_output" >output.json # save output
echo "Bicep deployment. Done"
