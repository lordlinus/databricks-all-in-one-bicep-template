// Create databricks cluster

param location string
param adbGlobalToken string
param azureApiToken string
param adbClusterName string
param adbSparkVersion string
param adbNodeType string
param adbNumWorkers string
param adbAutoTerminateMinutes string
param adbSparkConf string
param adbInitConfig string
param adbEnvVars string
param adbClusterLog string


resource createAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createAdbCluster'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'P1D'
    environmentVariables: [
      {
        name: 'ADB_GLOBAL_TOKEN'
        value: adbGlobalToken
      }
      {
        name: 'AZURE_API_TOKEN'
        value: azureApiToken
      }
      {
        name: 'DATABRICKS_CLUSTER_NAME'
        value: adbClusterName
      }
      {
        name: 'DATABRICKS_SPARK_VERSION'
        value: adbSparkVersion
      }
      {
        name: 'DATABRICKS_NODE_TYPE'
        value: adbNodeType
      }
      {
        name: 'DATABRICKS_NUM_WORKERS'
        value: adbNumWorkers
      }
      {
        name: 'DATABRICKS_AUTO_TERMINATE_MINUTES'
        value: adbAutoTerminateMinutes
      }
      {
        name: 'DATABRICKS_SPARK_CONF'
        value: adbSparkConf
      }
      {
        name: 'DATABRICKS_INIT_CONFIG'
        value: adbInitConfig
      }
      {
        name: 'DATABRICKS_ENV_VARS'
        value: adbEnvVars
      }
      {
        name: 'DATABRICKS_CLUSTER_LOG'
        value: adbClusterLog
      }
    ]
    scriptContent: loadTextContent('bashScripts/create_cluster.sh')
    cleanupPreference: 'OnExpiration'  
  }
}
