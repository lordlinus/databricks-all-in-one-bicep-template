param location string
resource mIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'myManagedIdentity'
  location: location
}

output mIdentityId string = mIdentity.id
