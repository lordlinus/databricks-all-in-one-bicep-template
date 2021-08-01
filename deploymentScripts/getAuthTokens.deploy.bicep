// Get auth tokens for all deployment scripts

param location string

resource getAuthTokens 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'getAuthTokens'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'P1D'
    scriptContent: loadTextContent('bashScripts/get_auth_tokens.sh')
    cleanupPreference: 'OnExpiration'  
  }
}

output adbGlobalToken string = reference('getAuthTokens').outputs.adbGlobalToken
output azureApiToken string = reference('getAuthTokens').outputs.azureApiToken
