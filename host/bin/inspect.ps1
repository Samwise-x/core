[CmdletBinding()]
param([string]$Root = 'D:\Samwise\host')
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMddTHHmmssfffZ'
$now = (Get-Date).ToUniversalTime().ToString('o')
function Capture([scriptblock]$Block) {
  try { ((& $Block 2>&1 | Out-String) -replace [char]0, '').Trim() }
  catch { $_.Exception.Message }
}
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$os = Get-CimInstance Win32_OperatingSystem
$wslFeature = Capture { (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State }
$vmpFeature = Capture { (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State }
$wslStatus = Capture { wsl.exe --status }
$distros = Capture { wsl.exe -l -q }
$dockerVersion = $null
$dockerRoot = $null
try {
  $dockerVersionOutput = & wsl.exe -d samwise-ubuntu -- docker info --format '{{.ServerVersion}}' 2>$null
  if ($LASTEXITCODE -eq 0 -and $dockerVersionOutput) {
    $dockerVersion = ($dockerVersionOutput | Out-String).Trim()
    $dockerRootOutput = & wsl.exe -d samwise-ubuntu -- docker info --format '{{.DockerRootDir}}' 2>$null
    if ($LASTEXITCODE -eq 0 -and $dockerRootOutput) { $dockerRoot = ($dockerRootOutput | Out-String).Trim() }
  }
} catch { $dockerVersion = $null; $dockerRoot = $null }
$wsl_docker = [ordered]@{
  engine_healthy = [bool]($dockerVersion -and $dockerRoot -eq '/var/lib/docker')
  server_version = $dockerVersion
  root_dir = $dockerRoot
  runtime = 'wsl2-native'
}
# ADR-0003: WSL2 is the intended tailnet node; Windows state is observed only as legacy.
$wslTailscale = $null
$wslServe = $null
try {
  $cli = & wsl.exe -d samwise-ubuntu -- sh -c 'command -v tailscale' 2>$null
  if ($LASTEXITCODE -eq 0 -and $cli) {
    $statusJson = & wsl.exe -d samwise-ubuntu -- tailscale status --json 2>$null
    if ($LASTEXITCODE -eq 0 -and $statusJson) {
      $wslTailscale = $statusJson | Out-String | ConvertFrom-Json
      $serveJson = & wsl.exe -d samwise-ubuntu -- tailscale serve status --json 2>$null
      if ($LASTEXITCODE -eq 0 -and $serveJson) { $wslServe = $serveJson | Out-String | ConvertFrom-Json }
    }
  }
} catch { $wslTailscale = $null; $wslServe = $null }
$legacyWinTailnet = $null
if (Get-Command tailscale.exe -ErrorAction SilentlyContinue) {
  try { $legacyWinTailnet = & tailscale.exe status --json | ConvertFrom-Json }
  catch { $legacyWinTailnet = $null }
}
$obs = [ordered]@{
  schema_version = 1
  contracts = @('ADR-0001','ADR-0003')
  observed_at = $now
  host = [ordered]@{
    computer_name = (hostname)
    os_caption = $os.Caption
    os_build = $os.BuildNumber
    cpu = $cpu.Name
    memory_bytes = [int64]$os.TotalVisibleMemorySize * 1KB
    d_free_bytes = if ($disk) { [int64]$disk.FreeSpace } else { $null }
  }
  wsl = [ordered]@{
    feature_state = $wslFeature
    virtual_machine_platform = $vmpFeature
    status = $wslStatus
    distros = $distros
    target_storage_exists = Test-Path 'D:\WSL\samwise-ubuntu'
  }
  tailscale = [ordered]@{
    target_owner = 'wsl2'
    backend_state = if ($wslTailscale) { $wslTailscale.BackendState } else { $null }
    hostname = if ($wslTailscale) { $wslTailscale.Self.HostName } else { $null }
    dns_name = if ($wslTailscale) { $wslTailscale.Self.DNSName } else { $null }
    magicdns_enabled = [bool]($wslTailscale -and $wslTailscale.CurrentTailnet.MagicDNSEnabled)
    active_serve_ports = if ($wslServe -and $wslServe.TCP) { @($wslServe.TCP.PSObject.Properties.Name | ForEach-Object {[int]$_}) } else { @() }
  }
  windows_tailnet_legacy = [ordered]@{
    backend_state = if ($legacyWinTailnet) { $legacyWinTailnet.BackendState } else { $null }
    hostname = if ($legacyWinTailnet) { $legacyWinTailnet.Self.HostName } else { $null }
  }
  docker = $wsl_docker
}
$path = Join-Path $Root "observations\$stamp.json"
$obs | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $path
([ordered]@{type='host_observation'; at=$now; path=$path} | ConvertTo-Json -Compress) | Add-Content -Encoding UTF8 "$Root\raw-observability.jsonl"
$obs | ConvertTo-Json -Depth 6
