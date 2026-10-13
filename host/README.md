# Windows/WSL host artifacts

Canonical source for `D:\Samwise\host` is maintained in this Git repository.
The Windows destination contains deployed scripts/configuration and runtime
observations; its generated observations, measurements, and checkpoints are not
authoritative Samwise cognitive history.

## Interfaces

- `bin/inspect.ps1`: write a timestamped host observation; discover Docker
  through the named WSL distribution, not the Windows PATH.
- `bin/verify.ps1`: independent **read-only structural observation** of WSL,
  Linux Docker Engine, Windows Tailscale, required paths, and frozen WSL
  resource settings. Emits JSON; exit 0 means host substrate matches the
  frozen host contract, exit 2 reports drift. It never authorizes a deployment.
- `bin/reconcile.ps1`: write operational checkpoint from inspection and
  verifier observations; benchmark only with explicit `-Benchmark`.
  It never marks the entire SAMWISE deployment as successfully converged.
- `bin/benchmark.ps1`: optional warm-path measurements without a WSL shutdown.

## Source and promotion

Run `host/tests/HostBoundary.Tests.ps1` through Pester on Windows.
A green local test suite is evidence for a candidate, not deployment authority.
Follow the two independent candidate/runtime gates recorded in the Core
Wayfinder before promoting this source to `D:\Samwise\host`.
Deploy the exact reviewed revision and preserve the previous deployed files
until independently observed acceptance. Historical D-drive evidence stays
on D: and is never copied into source control.

The accepted `host/desired.yaml` contract retains **4 processors** and
`D:\WSL\wsl-swap.vhdx`. Current machine observations show **6 processors**
and `D:\WSL\swap.vhdx`; `verify.ps1` reports that difference as drift,
rather than changing either configuration. Selecting a different desired
host topology is an explicit ADR/contract decision.

## Tailnet ownership: ADR-0003

The [accepted WSL-first host boundary](../docs/adr/0003-wsl-first-execution-and-windows-host-boundary.md)
assigns the single Tailscale node to WSL2. `host/network.yaml` encodes that
desired ownership and preserves the established port reservations. The existing
Windows Tailscale client is a **legacy observed state**, not a deployment
prerequisite or authority for a success claim.

Host verification reports both WSL tailnet readiness and the Windows legacy
observation. The migration itself requires an authorized, independently
verified deployment; this patch does not install or migrate Tailscale.
