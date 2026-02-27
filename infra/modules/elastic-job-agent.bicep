@description('Azure region for the Elastic Job Agent.')
param location string

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Name of the Elastic Job Agent resource.')
param elasticJobAgentName string

@description('Resource ID of the Elastic Job metadata database.')
param jobDatabaseId string

resource elasticJobAgent 'Microsoft.Sql/servers/jobAgents@2023-08-01-preview' = {
  name: '${sqlServerName}/${elasticJobAgentName}'
  location: location
  properties: {
    databaseId: jobDatabaseId
  }
}

output elasticJobAgentId string = elasticJobAgent.id
