@description('Name of the Azure SQL logical server.')
param sqlServerName string

@description('Name of the firewall rule.')
param ruleName string

@description('Start IP for the firewall rule.')
param startIpAddress string

@description('End IP for the firewall rule.')
param endIpAddress string

resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  name: '${sqlServerName}/${ruleName}'
  properties: {
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
  }
}

output firewallRuleId string = sqlFirewallRule.id
