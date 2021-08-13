param amlWorkspaceName string
param sslLeafName string
param aksAgentCount int
param aksAgentVMSize string
param aksAmlComputeName string

resource amlAks 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: '${amlWorkspaceName}/${aksAmlComputeName}'
  location: resourceGroup().location
  properties:{
    computeType: 'AKS'
    computeLocation: resourceGroup().location
    description: 'AKS cluster to provide inference REST endpoint'
    properties: {
      loadBalancerType:'PublicIp'
      agentCount: aksAgentCount
      agentVmSize:aksAgentVMSize
      aksNetworkingConfiguration:{
        dnsServiceIP:'10.0.0.1'
        dockerBridgeCidr: '172.17.0.1/16'
        serviceCidr:'10.0.0.0/16'
      }
      clusterPurpose:'FastProd'
      sslConfiguration:{
        leafDomainLabel: sslLeafName
        status: 'Auto'       
      }
    }
  }
}
