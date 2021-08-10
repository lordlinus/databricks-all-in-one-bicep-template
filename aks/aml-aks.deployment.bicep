param identity string
param location string = resourceGroup().location
param aksId string
param workspaceName string

resource linkAmlAks 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'linkAmlAks'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    timeout: 'PT5M'
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AKS_ID'
        value: aksId
      }
      {
        name: 'RG'
        value: resourceGroup().name
      }
      {
        name: 'WORKSPACE_NAME'
        value: workspaceName
      }
    ]
    scriptContent: loadTextContent('link_aml_aks.sh')
  }
}
