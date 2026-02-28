targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the Azure SQL logical server for the application database.')
param appSqlServerName string

@description('Name of the Azure SQL logical server for the Elastic Job metadata database.')
param jobSqlServerName string

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

module appSqlServer './modules/sql-server.bicep' = {
  name: 'app-sql-server-deployment'
  params: {
    location: location
    sqlServerName: appSqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

module jobSqlServer './modules/sql-server.bicep' = {
  name: 'job-sql-server-deployment'
  params: {
    location: location
    sqlServerName: jobSqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

module sqlDatabase './modules/sql-database.bicep' = {
  name: 'sql-application-database-deployment'
  params: {
    location: location
    sqlServerName: appSqlServer.outputs.sqlServerName
    databaseName: sqlDatabaseName
    databaseSkuName: sqlDatabaseSkuName
    databaseSkuTier: sqlDatabaseSkuTier
  }
}

module jobDatabase './modules/sql-database.bicep' = {
  name: 'sql-job-database-deployment'
  params: {
    location: location
    sqlServerName: jobSqlServer.outputs.sqlServerName
    databaseName: jobDatabaseName
    databaseSkuName: jobDatabaseSkuName
    databaseSkuTier: jobDatabaseSkuTier
  }
}

module allowAzureFirewallRule './modules/sql-firewall-rule.bicep' = if (allowAzureServices) {
  name: 'app-sql-firewall-allow-azure-services-deployment'
  params: {
    sqlServerName: appSqlServer.outputs.sqlServerName
    ruleName: 'AllowAzureServices'
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

module jobAllowAzureFirewallRule './modules/sql-firewall-rule.bicep' = if (allowAzureServices) {
  name: 'job-sql-firewall-allow-azure-services-deployment'
  params: {
    sqlServerName: jobSqlServer.outputs.sqlServerName
    ruleName: 'AllowAzureServices'
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

module customFirewallRule './modules/sql-firewall-rule.bicep' = if (deployCustomFirewallRule) {
  name: 'app-sql-firewall-custom-client-ip-deployment'
  params: {
    sqlServerName: appSqlServer.outputs.sqlServerName
    ruleName: 'AllowCustomClientIp'
    startIpAddress: customFirewallStartIp
    endIpAddress: customFirewallEndIp
  }
}

module jobCustomFirewallRule './modules/sql-firewall-rule.bicep' = if (deployCustomFirewallRule) {
  name: 'job-sql-firewall-custom-client-ip-deployment'
  params: {
    sqlServerName: jobSqlServer.outputs.sqlServerName
    ruleName: 'AllowCustomClientIp'
    startIpAddress: customFirewallStartIp
    endIpAddress: customFirewallEndIp
  }
}

module elasticJobAgent './modules/elastic-job-agent.bicep' = {
  name: 'sql-elastic-job-agent-deployment'
  params: {
    location: location
    sqlServerName: jobSqlServer.outputs.sqlServerName
    elasticJobAgentName: elasticJobAgentName
    jobDatabaseId: jobDatabase.outputs.databaseId
  }
}

output appSqlServerId string = appSqlServer.outputs.sqlServerId
output appSqlServerFqdn string = appSqlServer.outputs.sqlServerFqdn
output jobSqlServerId string = jobSqlServer.outputs.sqlServerId
output jobSqlServerFqdn string = jobSqlServer.outputs.sqlServerFqdn
output sqlDatabaseId string = sqlDatabase.outputs.databaseId
output jobDatabaseId string = jobDatabase.outputs.databaseId
output elasticJobAgentId string = elasticJobAgent.outputs.elasticJobAgentId
