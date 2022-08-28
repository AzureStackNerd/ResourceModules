@description('Optional. The location to deploy to')
param location string = resourceGroup().location

@description('Required. The name of the managed identity to create')
param virtualNetworkName string

@description('Required. The name of the Key Vault to create.')
param keyVaultName string

@description('Required. The name of the Managed Identity to create.')
param managedIdentityName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-01-01' = {
    name: virtualNetworkName
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                '10.0.0.0/24'
            ]
        }
        subnets: [
            {
                name: 'defaultSubnet'
                properties: {
                    addressPrefix: '10.0.0.0/24'
                }
            }
        ]
    }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
    name: managedIdentityName
    location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
    name: keyVaultName
    location: location
    properties: {
        sku: {
            family: 'A'
            name: 'standard'
        }
        tenantId: tenant().tenantId
        enablePurgeProtection: null
        enabledForTemplateDeployment: true
        enabledForDiskEncryption: true
        enabledForDeployment: true
        enableRbacAuthorization: true
        accessPolicies: []
    }

    resource key 'keys@2022-07-01' = {
        name: 'keyEncryptionKey'
        properties: {
            kty: 'RSA'
        }
    }
}

resource keyPermissions 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid('msi-${managedIdentity.name}-KeyVault-${keyVault.name}-Key-${keyVault::key.name}-Read-RoleAssignment')
    scope: keyVault::key
    properties: {
        principalId: managedIdentity.properties.principalId
        // Key Vault Crypto User
        roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424')
        principalType: 'ServicePrincipal'
    }
}

@description('The resource ID of the created Virtual Network Subnet.')
output subnetResourceId string = virtualNetwork.properties.subnets[0].id

@description('The resource ID of the created Key Vault.')
output keyVaultResourceId string = keyVault.id

@description('The resource ID of the created Managed Identity.')
output managedIdentityResourceId string = managedIdentity.id

@description('The name of the Key Vault Encryption Key.')
output keyVaultEncryptionKeyName string = keyVault::key.name
