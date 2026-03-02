@description('Azure region for the SQL logical server.')
param location string

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Administrator username for the SQL server.')
param sqlAdminLogin string

@secure()
@description('Administrator password for the SQL server.')
param sqlAdminPassword string

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
  }
}

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
