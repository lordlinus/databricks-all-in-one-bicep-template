param keyVaultName string
param LogAWkspId string

@secure()
param LogAWkspkey string
@secure()
param StorageAccountKey1 string
@secure()
param StorageAccountKey2 string
@secure()
param EventHubPK string


resource keyVaultAddSecretsLogAWkspId 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName}/LogAWkspId'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspId
  }
}
resource keyVaultAddSecretsLogAWkspkey 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName}/LogAWkspkey'
  properties: {
    contentType: 'text/plain'
    value: LogAWkspkey
  }
}
resource keyVaultAddSecretsStg1 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName}/StorageAccountKey1'
  properties: {
    contentType: 'text/plain'
    value: StorageAccountKey1
  }
}
resource keyVaultAddSecretsStg2 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName}/StorageAccountKey2'
  properties: {
    contentType: 'text/plain'
    value: StorageAccountKey2
  }
}
resource keyVaultAddSecretsEventHubPK 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVaultName}/EventHubPK'
  properties: {
    contentType: 'text/plain'
    value: EventHubPK
  }
}
