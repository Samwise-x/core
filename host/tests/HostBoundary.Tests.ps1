$Repo = (Get-Item -LiteralPath (Join-Path $PSScriptRoot '../..')).FullName
$HostDir = Join-Path $Repo 'host'
$Verify = Get-Content (Join-Path $HostDir 'bin/verify.ps1') -Raw
$Inspect = Get-Content (Join-Path $HostDir 'bin/inspect.ps1') -Raw
$Reconcile = Get-Content (Join-Path $HostDir 'bin/reconcile.ps1') -Raw
$Benchmark = Get-Content (Join-Path $HostDir 'bin/benchmark.ps1') -Raw

Describe 'Public seam: observe the WSL-native Docker Engine' {
    It 'queries the Linux Docker daemon through the named WSL distribution' {
        $Verify | Should Match 'wsl\.exe\s+-d\s+\$Distro\s+--\s+docker'
    }
    It 'exposes Docker runtime health separately from Windows Docker CLI presence' {
        $Verify | Should Match 'docker_engine_healthy'
        $Inspect | Should Match 'wsl_docker'
    }
    It 'reports actual WSL resource settings against the frozen desired-state contract' {
        $Verify | Should Match 'resource_drift'
        $Verify | Should Match '\.wslconfig'
    }
}

Describe 'Public seam: verify independently and read-only' {
    It 'has no observation, checkpoint, or runtime writes' {
        $Verify | Should Not Match '(?im)\b(Add-Content|Set-Content|Out-File|Remove-Item|New-Item|wsl\.exe\s+--shutdown)\b'
    }
    It 'does not equate a structural check with authoritative deployment success' {
        $Verify | Should Match 'deployment_success_authorized'
    }
}

Describe 'Public seam: reconcile without disrupting the running distro' {
    It 'does not shut down WSL' {
        $Reconcile | Should Not Match 'wsl\.exe\s+--shutdown'
        $Benchmark | Should Not Match 'wsl\.exe\s+--shutdown'
    }
    It 'does not implicitly run a benchmark or overwrite authoritative state' {
        $Reconcile | Should Not Match '(?m)^\s*&\s*["'']?\$Root\\bin\\benchmark\.ps1'
        $Reconcile | Should Match 'benchmark_opt_in'
    }
}

Describe 'Repository navigation and canonical source ownership' {
    It 'has canonical host scripts and configurations tracked by Core' {
        (Test-Path (Join-Path $HostDir 'bin/verify.ps1')) | Should Be $true
        (Test-Path (Join-Path $HostDir 'desired.yaml')) | Should Be $true
    }
    It 'points agents at existing canonical context rather than a missing root glossary' {
        $entry = Get-Content (Join-Path $Repo 'AGENTS.md') -Raw
        $entry | Should Not Match 'Read `CONTEXT\.md`, then `GLOSSARY\.md`'
    }
    It 'has the ADR-0003 contract referred to by both superseded Tailscale ADRs' {
        (Test-Path (Join-Path $Repo 'docs/adr/0003-wsl-first-execution-and-windows-host-boundary.md')) | Should Be $true
    }
}

Describe 'Live read-only behavior: actual GTX host' {
    It 'observes WSL Docker health and detects frozen-contract drift without writing D-drive evidence' {
        $file = Join-Path $HostDir 'bin/verify.ps1'
        $logs = @('D:\Samwise\host\raw-observability.jsonl', 'D:\Samwise\host\checkpoint.json')
        $before = @($logs | ForEach-Object { (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash })
        $raw = & pwsh -NoProfile -ExecutionPolicy Bypass -File $file -Root 'D:\Samwise\host'
        $exitCode = $LASTEXITCODE
        $result = $raw | Out-String | ConvertFrom-Json
        $result.deployment.target_distro_registered | Should Be $true
        $result.deployment.docker_engine_healthy | Should Be $true
        $result.deployment.docker_server_version | Should Match '^\d+\.\d+'
        $result.deployment.docker_root_dir | Should Be '/var/lib/docker'
        $result.network.node_owner_target | Should Be 'wsl2'
        $result.deployment_success_authorized | Should Be $false
        $result.resource_drift | Should Not Be $null
        $expectedExit = if ($result.host_ready_against_frozen_contract) { 0 } else { 2 }
        $exitCode | Should Be $expectedExit
        $after = @($logs | ForEach-Object { (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash })
        ($after -join ',') | Should Be ($before -join ',')
    }
}

Describe 'Boundary edge cases and deployable navigation' {
    It 'reports a missing requested WSL distribution instead of probing another one' {
        $file = Join-Path $HostDir 'bin/verify.ps1'
        $raw = & pwsh -NoProfile -ExecutionPolicy Bypass -File $file -Root 'D:\Samwise\host' -Distro '__samwise_nonexistent__'
        $exitCode = $LASTEXITCODE
        $result = $raw | Out-String | ConvertFrom-Json
        $result.deployment.target_distro_registered | Should Be $false
        $result.deployment.docker_engine_healthy | Should Be $false
        $exitCode | Should Be 2
    }
    It 'keeps optional benchmark scratch paths exclusive to the run' {
        $Benchmark | Should Not Match '/tmp/samwise-bench\.bin'
        $Benchmark | Should Not Match '/tmp/samwise-meta\b'
    }
    It 'maintains a deployed-agent entry and host context in canonical Core' {
        (Test-Path (Join-Path $HostDir 'AGENTS.md')) | Should Be $true
        (Test-Path (Join-Path $HostDir 'docs/CONTEXT.md')) | Should Be $true
    }
}

Describe 'PowerShell public entrypoint syntax' {
    It 'parses every staged host entrypoint without errors' {
        foreach ($script in (Get-ChildItem (Join-Path $HostDir 'bin') -Filter '*.ps1')) {
            $tokens = $null
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script.FullName, [ref]$tokens, [ref]$parseErrors
            )
            @($parseErrors).Count | Should Be 0
        }
    }
}

Describe 'Accepted ADR-0003: WSL-owned Tailscale node' {
    It 'probes the Linux Tailscale daemon through the WSL distribution' {
        $Verify | Should Match 'wsl\.exe\s+-d\s+\$Distro\s+--\s+tailscale'
    }
    It 'expresses Linux tailnet status separately from Windows legacy observations' {
        $Verify | Should Match 'wsl_tailscale_healthy'
        $Verify | Should Match 'windows_tailnet_legacy'
    }
    It 'does not take Windows Tailscale health as deployment eligibility' {
        $Verify | Should Not Match '\$tsCmd\s*=\s*Get-Command tailscale\.exe'
    }
    It 'keeps the network deployment contract under the WSL node authority' {
        $network = Get-Content (Join-Path $HostDir 'network.yaml') -Raw
        $network | Should Match '(?m)^\s*node_owner:\s*wsl2\s*$'
        $network | Should Match '(?m)^\s*wsl_tailnet_node:\s*true\s*$'
        $network | Should Not Match '(?m)^\s*node_owner:\s*windows-host\s*$'
    }
    It 'uses the upstream accepted ADR-0003 without creating a competing decision' {
        (Test-Path (Join-Path $Repo 'docs/adr/0003-tailscale-host-edge-and-port-contract.md')) | Should Be $false
    }
}
