targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Administrator username for the SQL server.')
param sqlAdminLogin string

@secure()
@description('Administrator password for the SQL server.')
param sqlAdminPassword string

@description('Name of the primary application database.')
param sqlDatabaseName string = 'appdb'

@description('SKU name for the primary application database (for example: S0, S1, GP_S_Gen5_2).')
param sqlDatabaseSkuName string = 'S0'

@description('SKU tier for the primary application database (for example: Standard, GeneralPurpose).')
param sqlDatabaseSkuTier string = 'Standard'

@description('Name of the Elastic Job metadata database.')
param jobDatabaseName string = 'jobdb'

@description('SKU name for the Elastic Job metadata database.')
param jobDatabaseSkuName string = 'S1'

@description('SKU tier for the Elastic Job metadata database.')
param jobDatabaseSkuTier string = 'Standard'

@description('Name of the Elastic Job Agent resource.')
param elasticJobAgentName string = 'elastic-job-agent'

@description('When true, creates the 0.0.0.0 firewall rule to allow Azure services.')
param allowAzureServices bool = true

@description('Optional start IP for a custom SQL firewall rule. Leave blank to skip custom firewall rule creation.')
param customFirewallStartIp string = ''

@description('Optional end IP for a custom SQL firewall rule. Leave blank to skip custom firewall rule creation.')
param customFirewallEndIp string = ''

var deployCustomFirewallRule = !empty(customFirewallStartIp) && !empty(customFirewallEndIp)

module sqlServer './modules/sql-server.bicep' = {
  name: 'sql-server-deployment'
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

module sqlDatabase './modules/sql-database.bicep' = {
  name: 'sql-application-database-deployment'
  params: {
    location: location
    sqlServerName: sqlServer.outputs.sqlServerName
    databaseName: sqlDatabaseName
    databaseSkuName: sqlDatabaseSkuName
    databaseSkuTier: sqlDatabaseSkuTier
  }
}

module jobDatabase './modules/sql-database.bicep' = {
  name: 'sql-job-database-deployment'
  params: {
    location: location
    sqlServerName: sqlServer.outputs.sqlServerName
    databaseName: jobDatabaseName
    databaseSkuName: jobDatabaseSkuName
    databaseSkuTier: jobDatabaseSkuTier
  }
}

module allowAzureFirewallRule './modules/sql-firewall-rule.bicep' = if (allowAzureServices) {
  name: 'sql-firewall-allow-azure-services-deployment'
  params: {
    sqlServerName: sqlServer.outputs.sqlServerName
    ruleName: 'AllowAzureServices'
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

module customFirewallRule './modules/sql-firewall-rule.bicep' = if (deployCustomFirewallRule) {
  name: 'sql-firewall-custom-client-ip-deployment'
  params: {
    sqlServerName: sqlServer.outputs.sqlServerName
    ruleName: 'AllowCustomClientIp'
    startIpAddress: customFirewallStartIp
    endIpAddress: customFirewallEndIp
  }
}

module elasticJobAgent './modules/elastic-job-agent.bicep' = {
  name: 'sql-elastic-job-agent-deployment'
  params: {
    location: location
    sqlServerName: sqlServer.outputs.sqlServerName
    elasticJobAgentName: elasticJobAgentName
    jobDatabaseId: jobDatabase.outputs.databaseId
  }
}

output sqlServerId string = sqlServer.outputs.sqlServerId
output sqlServerFqdn string = sqlServer.outputs.sqlServerFqdn
output sqlDatabaseId string = sqlDatabase.outputs.databaseId
output jobDatabaseId string = jobDatabase.outputs.databaseId
output elasticJobAgentId string = elasticJobAgent.outputs.elasticJobAgentId
