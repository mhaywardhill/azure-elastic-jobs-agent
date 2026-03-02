@description('Azure region for the SQL logical server.')
param location string

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Entra administrator login name (user, group, or service principal display name).')
param entraAdminLogin string

@description('Object ID (GUID) of the Entra administrator principal.')
param entraAdminObjectId string

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    administrators: {
      administratorType: 'ActiveDirectory'
      login: entraAdminLogin
      sid: entraAdminObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
