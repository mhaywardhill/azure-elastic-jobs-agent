[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$JobSqlServerName,

  [Parameter(Mandatory = $true)]
  [string]$JobDatabaseName,

  [Parameter(Mandatory = $true)]
  [string]$TargetGroupName,

  [Parameter(Mandatory = $true)]
  [string]$TargetServerName,

  [Parameter(Mandatory = $false)]
  [string]$TargetDatabaseName,

  [Parameter(Mandatory = $false)]
  [ValidateSet('Include', 'Exclude')]
  [string]$MembershipType = 'Include'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI (az) is required."
}

if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
  throw "Invoke-Sqlcmd is required. Install SqlServer module: Install-Module SqlServer -Scope CurrentUser"
}

$null = az account show | Out-Null
$accessToken = az account get-access-token --resource https://database.windows.net/ --query accessToken -o tsv

if ([string]::IsNullOrWhiteSpace($accessToken)) {
  throw "Failed to acquire Azure SQL access token via az account get-access-token."
}

$escapedTargetGroupName = $TargetGroupName.Replace("'", "''")
$escapedTargetServerName = $TargetServerName.Replace("'", "''")
$escapedMembershipType = $MembershipType.Replace("'", "''")

$targetType = 'SqlServer'
$databaseClause = ''

if (-not [string]::IsNullOrWhiteSpace($TargetDatabaseName)) {
  $targetType = 'SqlDatabase'
  $escapedTargetDatabaseName = $TargetDatabaseName.Replace("'", "''")
  $databaseClause = ",`n    @database_name = N'$escapedTargetDatabaseName'"
}

$query = @"
IF NOT EXISTS (
  SELECT 1
  FROM jobs.target_groups
  WHERE target_group_name = N'$escapedTargetGroupName'
)
BEGIN
  EXEC jobs.sp_add_target_group @target_group_name = N'$escapedTargetGroupName';
END;

EXEC jobs.sp_add_target_group_member
    @target_group_name = N'$escapedTargetGroupName',
    @target_type = N'$targetType',
    @server_name = N'$escapedTargetServerName'$databaseClause,
    @membership_type = N'$escapedMembershipType';
"@

$serverInstance = "$JobSqlServerName.database.windows.net"

Invoke-Sqlcmd `
  -ServerInstance $serverInstance `
  -Database $JobDatabaseName `
  -AccessToken $accessToken `
  -Query $query `
  -ConnectionTimeout 30 `
  -QueryTimeout 120

Write-Host "Target group '$TargetGroupName' configured on $serverInstance/$JobDatabaseName." -ForegroundColor Green
