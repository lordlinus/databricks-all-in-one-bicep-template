param location string
param pat_lifetime string
resource deployDatabricksCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployDatabricksCluster'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'P1D'
    environmentVariables:[
      {
        name: 'PAT_LIFETIME'
        value: pat_lifetime
      }
    ]
    primaryScriptUri: 'https://gist.githubusercontent.com/lordlinus/a84d88ecb19e69ea6f6246b584ee4106/raw/b89ab8addb9bd51a942b8b4426fdf16ff48ab58f/create_pat.sh'
    cleanupPreference: 'OnExpiration'  
  }  
}

output dsOutputs object = deployDatabricksCluster.properties
