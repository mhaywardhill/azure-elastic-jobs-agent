#!/usr/bin/env bash

set -euo pipefail

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI (az) is not installed or not in PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required for JSON merge logic." >&2
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  echo "Error: You are not logged in. Run: az login" >&2
  exit 1
fi

required_vars=(
  RESOURCE_GROUP
  APP_SQL_SERVER_NAME
  JOB_SQL_SERVER_NAME
  ELASTIC_JOB_AGENT_NAME
)

for var_name in "${required_vars[@]}"; do
  if [[ -z "${!var_name:-}" ]]; then
    echo "Error: Required environment variable '$var_name' is not set." >&2
    exit 1
  fi
done

TARGET_GROUP_NAME="${TARGET_GROUP_NAME:-serverGroup}"
TARGET_MEMBERSHIP_TYPE="${TARGET_MEMBERSHIP_TYPE:-Include}"
TARGET_DATABASE_NAME="${TARGET_DATABASE_NAME:-}"

if [[ "${TARGET_MEMBERSHIP_TYPE}" != "Include" && "${TARGET_MEMBERSHIP_TYPE}" != "Exclude" ]]; then
  echo "Error: TARGET_MEMBERSHIP_TYPE must be 'Include' or 'Exclude'." >&2
  exit 1
fi

target_type="SqlServer"
if [[ -n "${TARGET_DATABASE_NAME}" ]]; then
  target_type="SqlDatabase"
fi

subscription_id="$(az account show --query id -o tsv)"
base_resource_id="/subscriptions/${subscription_id}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Sql/servers/${JOB_SQL_SERVER_NAME}/jobAgents/${ELASTIC_JOB_AGENT_NAME}/targetGroups/${TARGET_GROUP_NAME}"
target_group_url="https://management.azure.com${base_resource_id}?api-version=2023-08-01"

temp_dir="$(mktemp -d)"
trap 'rm -rf "${temp_dir}"' EXIT

existing_json="${temp_dir}/existing.json"
request_body="${temp_dir}/request-body.json"

set +e
az rest --method get --url "${target_group_url}" --only-show-errors -o json > "${existing_json}" 2> "${temp_dir}/get.err"
get_exit_code=$?
set -e

if [[ ${get_exit_code} -ne 0 ]]; then
  if grep -qiE "ResourceNotFound|NotFound" "${temp_dir}/get.err"; then
    echo '{"properties":{"members":[]}}' > "${existing_json}"
  else
    echo "Error: Failed to read target group '${TARGET_GROUP_NAME}'." >&2
    cat "${temp_dir}/get.err" >&2
    exit ${get_exit_code}
  fi
fi

python3 - <<'PY' "${existing_json}" "${request_body}" "${target_type}" "${APP_SQL_SERVER_NAME}" "${TARGET_DATABASE_NAME}" "${TARGET_MEMBERSHIP_TYPE}"
import json
import sys

existing_path, output_path, target_type, server_name, database_name, membership = sys.argv[1:]

with open(existing_path, 'r', encoding='utf-8') as file:
    existing = json.load(file)

members = existing.get('properties', {}).get('members', [])
new_member = {
    'type': target_type,
    'serverName': server_name,
    'membershipType': membership,
}

if database_name:
    new_member['databaseName'] = database_name

for member in members:
    if all(member.get(key) == value for key, value in new_member.items()):
        body = {'properties': {'members': members}}
        with open(output_path, 'w', encoding='utf-8') as out:
            json.dump(body, out)
        sys.exit(0)

members.append(new_member)
body = {'properties': {'members': members}}

with open(output_path, 'w', encoding='utf-8') as out:
    json.dump(body, out)
PY

echo "Configuring target group '${TARGET_GROUP_NAME}' for agent '${ELASTIC_JOB_AGENT_NAME}'..."
az rest --method put --url "${target_group_url}" --body @"${request_body}" --only-show-errors -o json > /dev/null

echo "Target group '${TARGET_GROUP_NAME}' configured successfully."
echo "- Job server: ${JOB_SQL_SERVER_NAME}"
echo "- Target type: ${target_type}"
echo "- Target server: ${APP_SQL_SERVER_NAME}"
if [[ -n "${TARGET_DATABASE_NAME}" ]]; then
  echo "- Target database: ${TARGET_DATABASE_NAME}"
fi
