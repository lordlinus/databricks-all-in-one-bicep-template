@description('Storage Account Privatelink Resource')
param storageAccountPrivateLinkResource string

@description('Storage Account name')
param storageAccountName string

@description('Keyvault Private Link resource.')
param keyvaultPrivateLinkResource string

@description('keyvault name.')
param keyvaultName string

@description('event hub name.')
param eventHubName string

@description('EventHub Private Link resource.')
param eventHubPrivateLinkResource string

@description('Privatelink target sub resource DFS')
param targetSubResourceDfs string

@description('Privatelink target sub resource vault')
param targetSubResourceVault string

@description('Privatelink target sub resource Event Hub')
param targetSubResourceEventHub string

@description('Vnet name for private link')
param vnetName string

@description('Privatelink subnet Id')
param privateLinkSubnetId string

@description('Privatelink subnet Id')
param privateLinkLocation string = resourceGroup().location

var privateDnsNameStorage_var = 'privatelink.dfs.${environment().suffixes.storage}'
var storageAccountPrivateEndpointName_var = '${storageAccountName}privateendpoint'

var privateDnsNameVault_var = 'privatelink.vaultcore.azure.net'
var keyvaultPrivateEndpointName_var = '${keyvaultName}privateendpoint'

var privateDnsNameEventHub_var = 'privatelink.servicebus.windows.net'
var eventHubPrivateEndpointName_var = '${eventHubName}privateendpoint'

resource storageAccountPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: storageAccountPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: storageAccountPrivateEndpointName_var
        properties: {
          privateLinkServiceId: storageAccountPrivateLinkResource
          groupIds: [
            targetSubResourceDfs
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
  tags: {}
}
resource privateDnsNameStorage 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameStorage_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    storageAccountPrivateEndpointName
  ]
}
resource privateDnsNameStorage_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameStorage
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource storageAccountPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageAccountPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-dfs-core-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameStorage.id
        }
      }
    ]
  }
}

resource keyvaultPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: keyvaultPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyvaultPrivateEndpointName_var
        properties: {
          privateLinkServiceId: keyvaultPrivateLinkResource
          groupIds: [
            targetSubResourceVault
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
  tags: {}
}
resource privateDnsNameVault 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameVault_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    keyvaultPrivateEndpointName
  ]
}
resource privateDnsNameVault_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameVault
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource keyvaultPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: keyvaultPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsNameVault.id
        }
      }
    ]
  }
}

resource privateDnsNameEventHub_vnetName 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsNameEventHub
  name: vnetName
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
resource eventHubPrivateEndpointName 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: eventHubPrivateEndpointName_var
  location: privateLinkLocation
  properties: {
    privateLinkServiceConnections: [
      {
        name: eventHubPrivateEndpointName_var
        properties: {
          privateLinkServiceId: eventHubPrivateLinkResource
          groupIds: [
            targetSubResourceEventHub
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSubnetId
    }
  }
}
resource privateDnsNameEventHub 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsNameEventHub_var
  location: 'global'
  tags: {}
  properties: {}
  dependsOn: [
    eventHubPrivateEndpointName
  ]
}
resource eventHubPrivateEndpointName_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: eventHubPrivateEndpointName
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-servicebus-windows-net'
        properties: {
          privateDnsZoneId: privateDnsNameEventHub.id
        }
      }
    ]
  }
}
