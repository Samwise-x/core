[CmdletBinding()]
param([string]$Root = 'D:\Samwise\host')
$ErrorActionPreference = 'Stop'
$Distro = 'samwise-ubuntu'
$now = (Get-Date).ToUniversalTime().ToString('o')
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
$names = ((wsl.exe -l -q 2>&1 | Out-String) -replace [char]0, '').Trim()
$m = [ordered]@{
  schema_version = 2
  contract = 'ADR-0001'
  measured_at = $now
  measurement_mode = 'opt-in-non-disruptive-warm'
  cold_start_ms = $null
  d_free_bytes = if ($disk) { [int64]$disk.FreeSpace } else { $null }
  wsl_ready = [bool]($names -match '(?im)^\s*samwise-ubuntu\s*$')
}
if ($m.wsl_ready) {
  $warm = 1..5 | ForEach-Object {
    $duration = (Measure-Command { & wsl.exe -d $Distro -- true | Out-Null }).TotalMilliseconds
    if ($LASTEXITCODE -ne 0) { throw 'Warm start probe failed' }
    $duration
  }
  $sorted = @($warm | Sort-Object)
  $m.warm_start_ms_p50 = [math]::Round($sorted[2], 2)

  # Each invocation owns its own Linux-only scratch paths.
  $runId = [guid]::NewGuid().ToString('N')
  $scratchFile = "/tmp/samwise-$runId.bin"
  $scratchDir = "/tmp/samwise-$runId.meta"
  try {
    $writeSeconds = (Measure-Command {
      & wsl.exe -d $Distro -- dd if=/dev/zero "of=$scratchFile" bs=1M count=128 conv=fsync status=none
      if ($LASTEXITCODE -ne 0) { throw 'WSL write benchmark failed' }
    }).TotalSeconds
    $readSeconds = (Measure-Command {
      & wsl.exe -d $Distro -- dd "if=$scratchFile" of=/dev/null bs=1M status=none
      if ($LASTEXITCODE -ne 0) { throw 'WSL read benchmark failed' }
    }).TotalSeconds
    $metaScript = 'set -eu; mkdir "$1"; i=0; while [ "$i" -lt 1000 ]; do touch "$1/$i"; i=$((i+1)); done'
    $metaMs = (Measure-Command {
      & wsl.exe -d $Distro -- sh -c $metaScript sh $scratchDir
      if ($LASTEXITCODE -ne 0) { throw 'WSL metadata benchmark failed' }
    }).TotalMilliseconds
    $m.ext4_write_mbps = [math]::Round(128 / $writeSeconds, 2)
    $m.ext4_read_mbps = [math]::Round(128 / $readSeconds, 2)
    $m.metadata_create_1000_ms = [math]::Round($metaMs, 2)
  }
  finally {
    & wsl.exe -d $Distro -- rm -f -- $scratchFile | Out-Null
    & wsl.exe -d $Distro -- rm -rf -- $scratchDir | Out-Null
  }
}
else {
  $m.status = 'pending-wsl-distro'
}
($m | ConvertTo-Json -Compress) | Add-Content -Encoding UTF8 "$Root\measurements.jsonl"
([ordered]@{type='host_measurement'; at=$now; measurement=$m} | ConvertTo-Json -Depth 6 -Compress) |
  Add-Content -Encoding UTF8 "$Root\raw-observability.jsonl"
$m | ConvertTo-Json -Depth 6
