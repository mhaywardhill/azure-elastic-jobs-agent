# azure-elastic-jobs-agent

This repository contains Bicep templates to deploy:

- Azure SQL logical server
- Application database
- Elastic Job metadata database
- Azure SQL Elastic Job Agent
- Optional firewall rules

## Files

- `infra/main.bicep` - Entry-point template
- `infra/modules/sql-server.bicep` - SQL logical server
- `infra/modules/sql-database.bicep` - SQL database (reused for app + job DB)
- `infra/modules/sql-firewall-rule.bicep` - SQL firewall rules
- `infra/modules/elastic-job-agent.bicep` - SQL Elastic Job Agent
- `infra/main.parameters.json` - Sample deployment parameters

## Prerequisites

- Azure subscription
- Azure CLI logged in (`az login`)
- A target resource group

## Deploy

1. Update values in `infra/main.parameters.json`:
	 - `sqlServerName` must be globally unique.
	 - `sqlAdminPassword` must meet Azure SQL password complexity requirements.
	 - Optionally set `customFirewallStartIp` and `customFirewallEndIp`.

2. Create a resource group (if needed):

```bash
az group create --name <resource-group-name> --location <azure-region>
```

3. Deploy the Bicep template:

```bash
az deployment group create \
	--resource-group <resource-group-name> \
	--template-file infra/main.bicep \
	--parameters @infra/main.parameters.json
```

## Notes

- The Elastic Job Agent is linked to the `jobDatabaseName` database.
- `allowAzureServices=true` creates SQL firewall rule `AllowAzureServices` (`0.0.0.0`).
- If both custom firewall IP parameters are non-empty, `AllowCustomClientIp` is created.