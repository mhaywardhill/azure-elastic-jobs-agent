@description('Azure region for the SQL database.')
param location string

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Name of the SQL database.')
param databaseName string

@description('SKU name for the SQL database.')
param databaseSkuName string

@description('SKU tier for the SQL database.')
param databaseSkuTier string

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  name: '${sqlServerName}/${databaseName}'
  location: location
  sku: {
    name: databaseSkuName
    tier: databaseSkuTier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

output databaseId string = sqlDatabase.id
