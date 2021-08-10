@description('AKS cluster name')
param name string

@description('AKS cluster location')
param location string = resourceGroup().location

@description('vnet for nodes')
param vnetName string
var vnetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)

// need to give API server access to AML control plane here
resource symbolicname 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  properties: {
    // apiServerAccessProfile: {
    //   authorizedIPRanges: [
    //     '127.0.0.1'
    //   ]
    // }
    networkProfile: {
      loadBalancerSku: 'standard'
    }
    agentPoolProfiles: [
      {
        name: 'profile1'
        vnetSubnetID: vnetId
      }
    ]
  }
}
