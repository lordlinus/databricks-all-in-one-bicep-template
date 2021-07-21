@description('Azure datacentre Location to deploy the Firewall and IP Address')
param routeTableLocation string = resourceGroup().location

@description('Name of the Routing Table')
param routeTableName string

resource routeTableName_resource 'Microsoft.Network/routeTables@2020-08-01' = {
  name: routeTableName
  location: routeTableLocation
  properties: {
    disableBgpRoutePropagation: false
  }
}

resource routeTableName_Firewall_Route 'Microsoft.Network/routeTables/routes@2020-08-01' = {
  parent: routeTableName_resource
  name: 'Firewall-Route'
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: '10.0.1.4'
    hasBgpOverride: false
  }
}

output routeTblName string = routeTableName_resource.name
