param location string
// TODO: Check if the permission can be more specific
// get Owner permission using built in assignments 
// https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var ownerRoleDefId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'


resource mIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'myManagedIdentity'
  location: location
}

resource roleDef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: ownerRoleDefId
}

var ownerRoleAssignGuid = guid(mIdentity.id,roleDef.id)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: ownerRoleAssignGuid
  properties: {
    principalId: mIdentity.properties.principalId
    roleDefinitionId: startsWith(roleDef.id, 'Microsoft.Authorization') ? '/providers/${roleDef.id}' : roleDef.id
  }
}

output mIdentityId string = mIdentity.id
output mIdentityClientId string = mIdentity.properties.clientId
