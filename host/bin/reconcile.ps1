[CmdletBinding()]
param(
  [string]$Root = 'D:\Samwise\host',
  [switch]$Benchmark
)
$ErrorActionPreference = 'Stop'

# This operation produces a local continuation hint, never deployment authority.
$null = & "$PSScriptRoot\inspect.ps1" -Root $Root

# The verifier is read-only. It may return code 2 for observed drift.
$raw = & pwsh -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\verify.ps1" -Root $Root
$verifyExit = $LASTEXITCODE
if (-not $raw) { throw 'Read-only host verification returned no result' }
$verify = ($raw | Out-String | ConvertFrom-Json)

$next = if (-not $verify.structural_ready) {
  'restore-wsl-structure'
} elseif (-not $verify.deployment.docker_engine_healthy) {
  'restore-wsl-native-docker-engine'
} elseif (@($verify.resource_drift).Count -gt 0) {
  'resolve-frozen-wsl-resource-drift'
} elseif (-not $verify.network.backend_running) {
  'restore-host-tailscale'
} else {
  'resolve-bootstrap-acceptance-and-deployment-gates'
}
$benchmark_opt_in = [bool]$Benchmark
if ($benchmark_opt_in) {
  $null = & "$PSScriptRoot\benchmark.ps1" -Root $Root
}

$checkpoint = [ordered]@{
  schema_version = 2
  contracts = @('ADR-0001','ADR-0003')
  updated_at = (Get-Date).ToUniversalTime().ToString('o')
  phase = if ($verify.host_ready_against_frozen_contract) { 'substrate-ready' } else { 'substrate-drift' }
  network_frozen = $true
  network_reconciled = [bool]($verify.network.backend_running -and $verify.network.canonical_hostname -and $verify.network.magicdns_enabled)
  docker_engine_healthy = [bool]$verify.deployment.docker_engine_healthy
  resource_drift = @($verify.resource_drift)
  verifier_exit_code = $verifyExit
  benchmark_opt_in = $benchmark_opt_in
  next = $next
  converged = $false
  deployment_success_authorized = $false
}
$checkpoint | ConvertTo-Json -Depth 7 | Set-Content -Encoding UTF8 "$Root\checkpoint.json"
$checkpoint | ConvertTo-Json -Depth 7
