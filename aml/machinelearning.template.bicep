param keyVaultIdentifierId string
param storageAccount string
param amlWorkspaceName string
param containerRegistryName string
param applicationInsightsName string


resource ctrRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: containerRegistryName
  location: resourceGroup().location
  sku: {
    name: 'Basic'
  }
}

resource applicationInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: applicationInsightsName
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource aml 'Microsoft.MachineLearningServices/workspaces@2021-04-01' = {
  name: amlWorkspaceName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: amlWorkspaceName
    storageAccount: storageAccount
    keyVault: keyVaultIdentifierId
    applicationInsights: applicationInsightsName_resource.id
    containerRegistry: ctrRegistry.id
    allowPublicAccessWhenBehindVnet: false
  }
}

output amlId string = aml.id
output amlWkspName string = amlWorkspaceName
output amlProperties object = aml.properties
