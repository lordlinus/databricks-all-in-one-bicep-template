param location string
param force_update string = utcNow()
param identity string
param adb_pat_lifetime string
param adb_workspace_url string
param adb_workspace_id string
param adb_secret_scope_name string
param akv_id string
param akv_uri string

resource adbPATToken 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'adbPATToken'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'PAT_LIFETIME'
        value: adb_pat_lifetime
      }
    ]
    scriptContent: loadTextContent('deployment/create_pat.sh')
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
  }
}

resource secretScopeLink 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'secretScopeLink'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_SECRET_SCOPE_NAME'
        value: adb_secret_scope_name
      }
      {
        name: 'AKV_ID'
        value: akv_id
      }
      {
        name: 'AKV_URI'
        value: akv_uri
      }
    ]
    scriptContent: loadTextContent('deployment/create_secret_scope.sh')
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
  }
}

resource uploadFilesToAdb 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'uploadFilesToAdb'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
    ]
    scriptContent: loadTextContent('deployment/pre_cluster_create.sh')
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
  }
}

resource createAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'createCluster'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_SECRET_SCOPE_NAME'
        value: adb_secret_scope_name
      }
      {
        name: 'LINK_SECRET_SCOPE'
        value: secretScopeLink.properties.outputs.someVal
      }
    ]
    scriptContent: loadTextContent('deployment/create_cluster.sh')
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
  }
}

resource configAdbCluster 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'configCluster'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.0'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'ADB_WORKSPACE_URL'
        value: adb_workspace_url
      }
      {
        name: 'ADB_WORKSPACE_ID'
        value: adb_workspace_id
      }
      {
        name: 'ADB_CLUSTER_ID'
        value: createAdbCluster.properties.outputs.cluster_id
      }
    ]
    scriptContent: loadTextContent('deployment/post_cluster_create.sh')
    cleanupPreference: 'OnExpiration'
    forceUpdateTag: force_update
  }
}

output patOutput object = adbPATToken.properties
output akvLinkOutput object = secretScopeLink.properties
output adbCluster object = createAdbCluster.properties
