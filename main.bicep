targetScope = 'subscription'

@description('')
param userObjectId string
var storageSuffix = environment().suffixes.storage

@description('Auto generate prefix based on subscription')
param prefix string = uniqueString(guid(subscription().subscriptionId))

var storageAccountName = '${substring(prefix, 0, 10)}stg01'
var keyVaultName = '${substring(prefix, 0, 4)}kv01'
var resourceGroupName = '${substring(prefix, 0, 4)}-rg'
var adbWorkspaceName = '${substring(prefix, 0, 4)}AdbWksp'
var nsgName = '${substring(prefix, 0, 4)}nsg'
var firewallName = '${substring(prefix, 0, 4)}HubFW'
var firewallPublicIpName = '${substring(prefix, 0, 4)}FWPIp'
var fwRoutingTable = '${substring(prefix, 0, 4)}AdbRoutingTbl'
var clientPcName = '${substring(prefix, 0, 4)}ClientPc'
var eHNameSpace = 'eh${substring(prefix, 0, 4)}'
// creating the event hub same as namespace
var eventHubName = eHNameSpace 

@description('')
param hubVnetName string
@description('')
param spokeVnetName string
@description('')
param location string
@description('')
param adminUsername string
@description('')
@secure()
param adminPassword string

// @allowed([
//   'new'
//   'existing'
// ])
// @description('')
// param newOrExisting string = 'existing'

@description('')
param webappDestinationAddresses array
@description('')
param logBlobstorageDomains array
@description('')
param extendedInfraIp array
@description('')
param sccReplayDomain array
@description('')
param metastoreDomains array
@description('')
param eventHubEndpointDomain array
@description('')
param artifactBlobStoragePrimaryDomains array
@description('')
param SpokeVnetCidr string
@description('')
param HubVnetCidr string
@description('')
param PrivateSubnetCidr string
@description('')
param PublicSubnetCidr string
@description('')
param FirewallSubnetCidr string
@description('')
param PrivateLinkSubnetCidr string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module routeTable 'network/routetable.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'RouteTable'
  params: {
    routeTableName: fwRoutingTable
  }
}
module nsg 'network/securitygroup.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'NetworkSecurityGroup'
  params: {
    securityGroupName: nsgName
  }
}
module vnets 'network/vnet.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'HubandSpokeVNET'
  params: {
    hubVnetName: hubVnetName
    spokeVnetName: spokeVnetName
    routeTableName: routeTable.outputs.routeTblName
    securityGroupName: nsg.outputs.nsgName
    firewallSubnetCidr: FirewallSubnetCidr
    hubVnetCidr: HubVnetCidr
    spokeVnetCidr: SpokeVnetCidr
    publicSubnetCidr: PublicSubnetCidr
    privateSubnetCidr: PrivateSubnetCidr
    privatelinkSubnetCidr: PrivateLinkSubnetCidr
  }
}

module adb 'databricks/workspace.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'DatabricksWorkspace'
  params: {
    vnetName: spokeVnetName
    adbWorkspaceSkuTier: 'premium'
    adbWorkspaceName: adbWorkspaceName
  }
}

module hubFirewall 'network/firewall.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'HubFirewall'
  params: {
    firewallName: firewallName
    publicIpAddressName: firewallPublicIpName
    vnetName: hubVnetName
    webappDestinationAddresses: webappDestinationAddresses
    logBlobstorageDomains: logBlobstorageDomains
    infrastructureDestinationAddresses: extendedInfraIp
    sccRelayDomains: sccReplayDomain
    metastoreDomains: metastoreDomains
    eventHubEndpointDomains: eventHubEndpointDomain
    artifactBlobStoragePrimaryDomains: artifactBlobStoragePrimaryDomains
    dbfsBlobStrageDomain: array('${adb.outputs.databricks_dbfs_storage_accountName}.blob.${storageSuffix}')
    clientPrivateIpAddr: clientpc.outputs.clientPrivateIpaddr
  }
}

module adlsGen2 'storage/storageaccount.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'StorageAccount'
  params: {
    storageAccountName: storageAccountName
  }
}

module keyVault 'keyvault/keyvault.template.bicep' =  {
  scope: resourceGroup(rg.name)
  name: 'KeyVault'
  params: {
    keyVaultName: keyVaultName
    objectId: userObjectId
  }
}

module clientpc 'other/clientdevice.template.bicep' = {
  name: 'ClientPC'
  scope: resourceGroup(rg.name)
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetName: hubVnetName
    clientPcName: clientPcName
  }
  dependsOn: [
    vnets
  ]
}

module loganalytics 'monitor/loganalytics.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'loganalytics'
}

module eventHubLogging 'monitor/eventhub.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'EventHub'
  params: {
    namespaceName: eHNameSpace
  }
}

module privateEndPoints 'network/privateendpoint.template.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'PrivateEndPoints'
  params: {
    keyvaultName: keyVault.name
    keyvaultPrivateLinkResource: keyVault.outputs.keyvault_id
    privateLinkSubnetId: vnets.outputs.privatelinksubnet_id
    storageAccountName: adlsGen2.name
    storageAccountPrivateLinkResource: adlsGen2.outputs.storageaccount_id
    eventHubName: eventHubName
    eventHubPrivateLinkResource: eventHubLogging.outputs.eHNamespaceId
    targetSubResourceDfs: 'dfs'
    targetSubResourceVault: 'vault'
    targetSubResourceEventHub: 'namespace'
    vnetName: spokeVnetName
  }
}

output resourceGroupName string = rg.name
output keyVaultName string = keyVaultName
output adbWorkspaceName string = adbWorkspaceName
output storageAccountName string = storageAccountName
output storageKey1 string = adlsGen2.outputs.key1
output storageKey2 string = adlsGen2.outputs.key2
output databricksWksp string = adb.outputs.databricks_workspace_id
output databricks_workspaceUrl string = adb.outputs.databricks_workspaceUrl
output keyvault_id string = keyVault.outputs.keyvault_id
output keyvault_uri string = keyVault.outputs.keyvault_uri
output logAnalyticsWkspId string = loganalytics.outputs.logAnalyticsWkspId
output logAnalyticsprimarySharedKey string = loganalytics.outputs.primarySharedKey
output logAnalyticssecondarySharedKey string = loganalytics.outputs.secondarySharedKey
output eHNamespaceId string = eventHubLogging.outputs.eHNamespaceId
output eHubNameId string = eventHubLogging.outputs.eHubNameId
output eHAuthRulesId string = eventHubLogging.outputs.eHAuthRulesId
output eHPConnString string = eventHubLogging.outputs.eHPConnString
