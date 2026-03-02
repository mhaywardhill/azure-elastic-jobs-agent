#!/usr/bin/env bash

set -euo pipefail

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) is not installed or not in PATH." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: You are not logged in. Run: az login" >&2
  exit 1
fi

required_vars=(
  RESOURCE_GROUP
  LOCATION
  APP_SQL_SERVER_NAME
  JOB_SQL_SERVER_NAME
  ENTRA_SQL_SERVER_NAME
  ENTRA_ADMIN_LOGIN
  ENTRA_ADMIN_OBJECT_ID
  ENTRA_TENANT_ID
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Error: Required environment variable '$var_name' is not set." >&2
    exit 1
  fi
done

SQL_DATABASE_NAME="${SQL_DATABASE_NAME:-appdb}"
SQL_DATABASE_SKU_NAME="${SQL_DATABASE_SKU_NAME:-S0}"
SQL_DATABASE_SKU_TIER="${SQL_DATABASE_SKU_TIER:-Standard}"
JOB_DATABASE_NAME="${JOB_DATABASE_NAME:-jobdb}"
JOB_DATABASE_SKU_NAME="${JOB_DATABASE_SKU_NAME:-S1}"
JOB_DATABASE_SKU_TIER="${JOB_DATABASE_SKU_TIER:-Standard}"
ELASTIC_JOB_AGENT_NAME="${ELASTIC_JOB_AGENT_NAME:-elastic-job-agent}"
ALLOW_AZURE_SERVICES="${ALLOW_AZURE_SERVICES:-true}"
CUSTOM_FIREWALL_START_IP="${CUSTOM_FIREWALL_START_IP:-}"
CUSTOM_FIREWALL_END_IP="${CUSTOM_FIREWALL_END_IP:-}"

if [[ -n "${CUSTOM_FIREWALL_START_IP}" && -z "${CUSTOM_FIREWALL_END_IP}" ]]; then
  echo "Error: CUSTOM_FIREWALL_END_IP is required when CUSTOM_FIREWALL_START_IP is set." >&2
  exit 1
fi

if [[ -n "${CUSTOM_FIREWALL_END_IP}" && -z "${CUSTOM_FIREWALL_START_IP}" ]]; then
  echo "Error: CUSTOM_FIREWALL_START_IP is required when CUSTOM_FIREWALL_END_IP is set." >&2
  exit 1
fi

echo "Ensuring resource group '${RESOURCE_GROUP}' exists in '${LOCATION}'..."
az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" >/dev/null

echo "Deploying Azure SQL + Elastic Job Agent resources..."
az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "infra/main.bicep" \
  --parameters \
    location="${LOCATION}" \
    appSqlServerName="${APP_SQL_SERVER_NAME}" \
    jobSqlServerName="${JOB_SQL_SERVER_NAME}" \
    entraSqlServerName="${ENTRA_SQL_SERVER_NAME}" \
    entraAdminLogin="${ENTRA_ADMIN_LOGIN}" \
    entraAdminObjectId="${ENTRA_ADMIN_OBJECT_ID}" \
    entraTenantId="${ENTRA_TENANT_ID}" \
    sqlDatabaseName="${SQL_DATABASE_NAME}" \
    sqlDatabaseSkuName="${SQL_DATABASE_SKU_NAME}" \
    sqlDatabaseSkuTier="${SQL_DATABASE_SKU_TIER}" \
    jobDatabaseName="${JOB_DATABASE_NAME}" \
    jobDatabaseSkuName="${JOB_DATABASE_SKU_NAME}" \
    jobDatabaseSkuTier="${JOB_DATABASE_SKU_TIER}" \
    elasticJobAgentName="${ELASTIC_JOB_AGENT_NAME}" \
    allowAzureServices="${ALLOW_AZURE_SERVICES}" \
    customFirewallStartIp="${CUSTOM_FIREWALL_START_IP}" \
    customFirewallEndIp="${CUSTOM_FIREWALL_END_IP}"

echo "Deployment completed successfully."
