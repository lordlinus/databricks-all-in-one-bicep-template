@description('Azure datacentre Location to deploy the Firewall and IP Address')
param firewalllocation string = resourceGroup().location

@description('Name of the IP Address')
param publicIpAddressName string

@description('Name of the Azure Firewall')
param firewallName string

@description('Firewall SKU')
param firewallSKU string = 'Standard'

@description('Client Private ip address')
param clientPrivateIpAddr string

@description('Name of the vnet associated witht he Firewall')
param vnetName string

@description('List of destination IP addresses for Web App')
param webappDestinationAddresses array = []

@description('List of Log Blob storage domain name')
param logBlobstorageDomains array = []

@description('List of destination IP addresses for Extended Infrastructure')
param infrastructureDestinationAddresses array = []

@description('List of SCC relay domain name')
param sccRelayDomains array = []

@description('List of Metastore domain name')
param metastoreDomains array = []

@description('List of Event Hub endpoint domain name')
param eventHubEndpointDomains array = []

@description('List of Artifact Blob storage primary domain name')
param artifactBlobStoragePrimaryDomains array = []

@description('the domain name of DBFS root Blob storage')
param dbfsBlobStrageDomain array = []

var storageSuffix = environment().suffixes.storage


resource publicIpAddressName_resource 'Microsoft.Network/publicIpAddresses@2019-02-01' = {
  name: publicIpAddressName
  location: firewalllocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: {}
}

resource firewallName_resource 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: firewallName
  location: firewalllocation
  properties: {
    ipConfigurations: [
      {
        name: publicIpAddressName
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: publicIpAddressName_resource.id
          }
        }
      }
    ]
    sku: {
      tier: firewallSKU
    }
    threatIntelMode: 'Alert'
    additionalProperties: {
      'Network.DNS.EnableProxy': 'true'
    }
    natRuleCollections:[
      {
        name: 'Allow-RDP-DNAT'
        properties:{
          priority: 100
          action:{
            type: 'Dnat'
          }
          rules:[
            {
              name: 'rdp-dnat'
              protocols: [
                'TCP'
              ]
              sourceAddresses:[
                '*'
              ]
              destinationAddresses: [
                publicIpAddressName_resource.properties.ipAddress
              ]
              destinationPorts:[
                '3389'
              ]
              translatedAddress: clientPrivateIpAddr
              translatedPort: '3389'
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'Allow-Databricks-Services'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Webapp IP'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: webappDestinationAddresses
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '*'
              ]
            }
            {
              name: 'Extended infrastructure IP'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: infrastructureDestinationAddresses
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: []
              destinationPorts: [
                '*'
              ]
            }
            {
              name: 'Metastore IP'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: []
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: metastoreDomains
              destinationPorts: [
                '*'
              ]
            }
            {
              name: 'Event Hub endpoint'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: []
              sourceIpGroups: []
              destinationIpGroups: []
              destinationFqdns: eventHubEndpointDomains
              destinationPorts: [
                '*'
              ]
            }
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'Allow-Databricks-Services'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Log Blob storage IP'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: logBlobstorageDomains
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'SCC Relay IP'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: sccRelayDomains
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'Artifact Blob storage IP'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: artifactBlobStoragePrimaryDomains
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'DBFS root Blob storage IP'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: dbfsBlobStrageDomain
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
          ]
        }
      }
      {
        name: 'Allow-Websites'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'Pypi'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*.pypi.org'
                '*.pythonhosted.org'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'Maven'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*.mvnrepository.com'
                '*.maven.org'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }            
            {
              name: 'GitHubScripts'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*.githubusercontent.com'
                'github.com'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
            {
              name: 'LogAnalytics'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*.ods.opinsights.azure.com'
                '*.oms.opinsights.azure.com'
                '*.blob.${storageSuffix}'
                '*.azure-automation.net'
              ]
              sourceAddresses: [
                '*'
              ]
              sourceIpGroups: []
            }
          ]
        }
      }
    ]
  }
  tags: {}
}
