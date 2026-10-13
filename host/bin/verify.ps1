[CmdletBinding()]
param(
    [string]$Root = 'D:\Samwise\host',
    [string]$Distro = 'samwise-ubuntu'
)
$ErrorActionPreference = 'Stop'

# Independent, read-only observation: this script never creates runtime evidence,
# deploys an artifact, or grants deployment-success authority.
$required = @(
    'D:\WSL\samwise-ubuntu\ext4.vhdx',
    "$Root\desired.yaml",
    "$Root\network.yaml",
    "$Root\observations",
    "$Root\raw-observability.jsonl",
    "$Root\checkpoint.json",
    "$Root\measurements.jsonl"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_) })

$distros = ((& wsl.exe -l -q 2>&1 | Out-String) -replace [char]0, '').Trim()
$registered = [bool]($distros -match ('(?im)^\s*' + [regex]::Escape($Distro) + '\s*$'))

$dockerVersion = $null
$dockerRoot = $null
$dockerHealthy = $false
if ($registered) {
    $versionOutput = & wsl.exe -d $Distro -- docker info --format '{{.ServerVersion}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $versionOutput) {
        $dockerVersion = ($versionOutput | Out-String).Trim()
        $rootOutput = & wsl.exe -d $Distro -- docker info --format '{{.DockerRootDir}}' 2>$null
        if ($LASTEXITCODE -eq 0 -and $rootOutput) {
            $dockerRoot = ($rootOutput | Out-String).Trim()
            $dockerHealthy = ($dockerRoot -eq '/var/lib/docker')
        }
    }
}

# ADR-0003 places the canonical tailnet node in WSL2.
# Observe the still-deployed Windows client separately as transition evidence.
$wslTailscalePresent = $false
$wslTs = $null
if ($registered) {
    try {
        $tsPath = & wsl.exe -d $Distro -- sh -c 'command -v tailscale' 2>$null
        $wslTailscalePresent = ($LASTEXITCODE -eq 0 -and [bool]$tsPath)
        if ($wslTailscalePresent) {
            $wslTsOutput = & wsl.exe -d $Distro -- tailscale status --json 2>$null
            if ($LASTEXITCODE -eq 0 -and $wslTsOutput) {
                $wslTs = ($wslTsOutput | Out-String | ConvertFrom-Json)
            }
        }
    } catch {
        $wslTs = $null
    }
}
$legacyWinCli = Get-Command tailscale.exe -ErrorAction SilentlyContinue
$legacyWinTs = $null
if ($legacyWinCli) {
    try {
        $legacyWinTs = & tailscale.exe status --json | ConvertFrom-Json
    } catch { $legacyWinTs = $null }
}
$wslTailnetHealthy = [bool]($wslTs -and $wslTs.BackendState -eq 'Running')
$network = [ordered]@{
    node_owner_target = 'wsl2'
    tailscale_present = $wslTailscalePresent
    backend_running = $wslTailnetHealthy
    wsl_tailscale_healthy = $wslTailnetHealthy
    canonical_hostname = [bool]($wslTs -and $wslTs.Self.HostName -eq 'gtx1660')
    magicdns_enabled = [bool]($wslTs -and $wslTs.CurrentTailnet.MagicDNSEnabled)
    windows_tailnet_legacy = [ordered]@{
        cli_present = [bool]$legacyWinCli
        backend_running = [bool]($legacyWinTs -and $legacyWinTs.BackendState -eq 'Running')
        hostname = if ($legacyWinTs) { $legacyWinTs.Self.HostName } else { $null }
    }
}

$desired = if (Test-Path -LiteralPath "$Root\desired.yaml") { Get-Content -LiteralPath "$Root\desired.yaml" -Raw } else { '' }
$cfgPath = Join-Path $env:USERPROFILE '.wslconfig'
$cfg = if (Test-Path -LiteralPath $cfgPath) { Get-Content -LiteralPath $cfgPath -Raw } else { '' }

# Read only the stable scalars from the existing, frozen desired.yaml contract.
# Configuration is reported as drift, not silently rewritten.
function Scalar([string]$text, [string]$pattern) {
    $m = [regex]::Match($text, $pattern)
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $null
}
function NormPath([string]$p) {
    if ($null -eq $p) { return $null }
    return (($p.Trim().Trim([char]39, [char]34)) -replace '\\\\', '\').ToLowerInvariant()
}
$expected = [ordered]@{
    memory = Scalar $desired '(?im)^\s*memory:\s*([^\r\n#]+)'
    processors = Scalar $desired '(?im)^\s*processors:\s*(\d+)'
    swap = Scalar $desired '(?im)^\s*swap:\s*([^\r\n#]+)'
    swap_file = Scalar $desired '(?im)^\s*swap_file:\s*([^\r\n#]+)'
}
$observed = [ordered]@{
    memory = Scalar $cfg '(?im)^\s*memory\s*=\s*([^\r\n#]+)'
    processors = Scalar $cfg '(?im)^\s*processors\s*=\s*(\d+)'
    swap = Scalar $cfg '(?im)^\s*swap\s*=\s*([^\r\n#]+)'
    swap_file = Scalar $cfg '(?im)^\s*swapFile\s*=\s*([^\r\n#]+)'
}
$resource_drift = @()
foreach ($key in $expected.Keys) {
    $want = $expected[$key]
    $have = $observed[$key]
    if ($key -eq 'swap_file') {
        $want = NormPath $want
        $have = NormPath $have
    } else {
        if ($null -ne $want) { $want = $want.Trim([char]39, [char]34).ToLowerInvariant() }
        if ($null -ne $have) { $have = $have.Trim([char]39, [char]34).ToLowerInvariant() }
    }
    if ($null -eq $want -or $null -eq $have -or $want -ne $have) {
        $resource_drift += [ordered]@{ setting = $key; expected = $want; observed = $have }
    }
}
$structural = ($missing.Count -eq 0) -and $registered
$networkConfig = if (Test-Path -LiteralPath "$Root\network.yaml") { Get-Content -LiteralPath "$Root\network.yaml" -Raw } else { '' }
$networkContractMatch = [bool]($networkConfig -match '(?m)^\s*node_owner:\s*wsl2\s*$' -and
    $networkConfig -match '(?m)^\s*wsl_tailnet_node:\s*true\s*$')
$network['contract_matches_adr0003'] = $networkContractMatch
$networkReady = $network.wsl_tailscale_healthy -and $network.canonical_hostname -and $network.magicdns_enabled -and $networkContractMatch
$hostReady = $structural -and $dockerHealthy -and $networkReady -and ($resource_drift.Count -eq 0)

$result = [ordered]@{
    schema_version = 2
    contracts = @('ADR-0001', 'ADR-0003')
    verified_at = (Get-Date).ToUniversalTime().ToString('o')
    structural_ready = [bool]$structural
    host_ready_against_frozen_contract = [bool]$hostReady
    deployment_success_authorized = $false
    missing = @($missing)
    resource_drift = @($resource_drift)
    network = $network
    deployment = [ordered]@{
        target_distro_registered = $registered
        docker_engine_healthy = $dockerHealthy
        docker_server_version = $dockerVersion
        docker_root_dir = $dockerRoot
        docker_runtime = 'wsl2-native'
        windows_docker_cli_required = $false
    }
}
$result | ConvertTo-Json -Depth 7
if (-not $hostReady) { exit 2 }
