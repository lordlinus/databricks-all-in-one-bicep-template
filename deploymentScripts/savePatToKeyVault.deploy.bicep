// Saves personal access token into keyvault

param location string
param adbGlobalToken string
param azureApiToken string
param adbId string
param adbWorkspaceUrl string
param patLifetime string
param akvName string

resource savePatInKeyVault 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'savePatInKeyVault'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'ADB_GLOBAL_TOKEN'
        value: adbGlobalToken
      }
      {
        name: 'AZURE_API_TOKEN'
        value: azureApiToken
      }
      {
        name: 'ADB_ID'
        value: adbId
      }
      {
        name: 'ADB_WORKSPACE_URL'
        value: adbWorkspaceUrl
      }
      {
        name: 'PAT_LIFETIME'
        value: patLifetime
      }
      {
        name: 'AKV_NAME'
        value: akvName
      }
    ]
    scriptContent: loadTextContent('bashScripts/create_pat.sh')
    cleanupPreference: 'OnExpiration'  
  }
}

