# Azure SQL Elastic Jobs Agent (Bicep)

Infrastructure-as-Code templates to provision an Azure SQL environment with an Elastic Job Agent using modular Bicep components.

## Overview

This deployment creates:

- Azure SQL logical server for application database
- Azure SQL logical server for Elastic Job metadata database
- Primary application database
- Elastic Job metadata database
- Azure SQL Elastic Job Agent
- Optional SQL firewall rules

## Architecture

```mermaid
flowchart TD
  RG[Resource Group] --> APP_SQL[App Azure SQL Server]
  RG --> JOB_SQL[Job Azure SQL Server]
  APP_SQL --> APPDB[Application Database]
  JOB_SQL --> JOBDB[Job Metadata Database]
  JOB_SQL --> AGENT[Elastic Job Agent]
    AGENT --> JOBDB

  APP_SQL --> APP_FW1[Firewall Rule: AllowAzureServices]
  APP_SQL --> APP_FW2[Firewall Rule: AllowCustomClientIp]
  JOB_SQL --> JOB_FW1[Firewall Rule: AllowAzureServices]
  JOB_SQL --> JOB_FW2[Firewall Rule: AllowCustomClientIp]
```

## Repository Structure

- `deploy.sh`: Deploys using exported environment variables
- `infra/main.bicep`: Deployment entry point and module orchestration
- `infra/modules/sql-server.bicep`: SQL logical server
- `infra/modules/sql-database.bicep`: Reusable SQL database module
- `infra/modules/sql-firewall-rule.bicep`: Reusable SQL firewall rule module
- `infra/modules/elastic-job-agent.bicep`: Elastic Job Agent
- `infra/main.parameters.json`: Example parameter values

## Prerequisites

- Azure subscription with permissions to deploy SQL resources
- Azure CLI installed and authenticated (`az login`)
- Existing or new resource group target

## Deployment

### Option 1: Deploy with exported environment variables (recommended)

1. Export required variables:

```bash
export RESOURCE_GROUP="rg-sql-jobs-dev"
export LOCATION="eastus"
export APP_SQL_SERVER_NAME="<globally-unique-app-sql-server-name>"
export JOB_SQL_SERVER_NAME="<globally-unique-job-sql-server-name>"
export SQL_ADMIN_LOGIN="sqladminuser"
export SQL_ADMIN_PASSWORD="<strong-password>"
```

2. Export optional variables as needed:

```bash
export SQL_DATABASE_NAME="appdb"
export SQL_DATABASE_SKU_NAME="S0"
export SQL_DATABASE_SKU_TIER="Standard"
export JOB_DATABASE_NAME="jobdb"
export JOB_DATABASE_SKU_NAME="S1"
export JOB_DATABASE_SKU_TIER="Standard"
export ELASTIC_JOB_AGENT_NAME="elastic-job-agent"
export ALLOW_AZURE_SERVICES="true"
export CUSTOM_FIREWALL_START_IP=""
export CUSTOM_FIREWALL_END_IP=""
```

3. Run the deployment script:

```bash
./deploy.sh
```

The script validates required variables, ensures the resource group exists, and deploys `infra/main.bicep`.

### Option 2: Deploy with parameter file

1. Update `infra/main.parameters.json`:
  - `appSqlServerName` and `jobSqlServerName` must both be globally unique.
  - `sqlAdminPassword` must satisfy Azure SQL complexity requirements.
  - Optionally set `customFirewallStartIp` and `customFirewallEndIp`.

2. Create a resource group (if needed):

```bash
az group create --name <resource-group-name> --location <azure-region>
```

3. Deploy the templates:

```bash
az deployment group create \
  --resource-group <resource-group-name> \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

## Key Parameters

- `appSqlServerName`: Application database logical server name (global uniqueness required)
- `jobSqlServerName`: Job metadata database logical server name (global uniqueness required)
- `sqlAdminLogin` / `sqlAdminPassword`: SQL administrator credentials
- `sqlDatabaseName`: Application database name
- `jobDatabaseName`: Elastic Job metadata database name
- `elasticJobAgentName`: Elastic Job Agent resource name
- `allowAzureServices`: Creates `AllowAzureServices` firewall rule when `true`
- `customFirewallStartIp` / `customFirewallEndIp`: Creates `AllowCustomClientIp` when both are provided

For `deploy.sh`, these map to the following environment variables:

- `appSqlServerName` -> `APP_SQL_SERVER_NAME`
- `jobSqlServerName` -> `JOB_SQL_SERVER_NAME`
- `sqlAdminLogin` -> `SQL_ADMIN_LOGIN`
- `sqlAdminPassword` -> `SQL_ADMIN_PASSWORD`
- `sqlDatabaseName` -> `SQL_DATABASE_NAME`
- `jobDatabaseName` -> `JOB_DATABASE_NAME`
- `elasticJobAgentName` -> `ELASTIC_JOB_AGENT_NAME`
- `allowAzureServices` -> `ALLOW_AZURE_SERVICES`
- `customFirewallStartIp` -> `CUSTOM_FIREWALL_START_IP`
- `customFirewallEndIp` -> `CUSTOM_FIREWALL_END_IP`

## Outputs

The deployment returns:

- App SQL server resource ID
- App SQL server fully qualified domain name
- Job SQL server resource ID
- Job SQL server fully qualified domain name
- Application database resource ID
- Job database resource ID
- Elastic Job Agent resource ID

## Operational Notes

- The Elastic Job Agent is bound to the job metadata database.
- Restrict firewall access to required IP ranges for production.
- Store secrets securely (for example, Azure Key Vault) instead of committing credentials.