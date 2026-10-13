# Windows substrate glossary

Reference for the SAMWISE Windows host layer on gtx1660. Load when naming paths, ownership, or self-healing steps. Companion: [CONTEXT.md](CONTEXT.md).

## Leading words

| Word | Meaning |
|---|---|
| _substrate_ | Windows owns disks, WSL registration, display integration, recovery access, and `D:\Samwise\host`; WSL2 owns the Samwise Docker Engine and intended Tailscale node. |
| _reconcile_ | Observe the machine, run read-only structural verification, then update the operational checkpoint. Benchmarking is explicit opt-in. |
| _observation_ | Timestamped JSON under `observations\`. Evidence only. Not authoritative truth. |
| _checkpoint_ | `checkpoint.json`. Continuity hint for the next human/agent step. Not durable cognitive memory. |
| _desired_ | `desired.yaml` (ADR-0001, status frozen). The Windows/WSL placement contract this host converges toward. |

## Namespace (frozen desired)

| Path | Role |
|---|---|
| `D:\Samwise\host` | Windows substrate root: scripts, observations, checkpoint. |
| `D:\WSL` | Linux storage root for WSL2 VHDs. |
| `D:\WSL\samwise-ubuntu` | Target install location for distro `samwise-ubuntu` (source Ubuntu-24.04). |
| `D:\WSL\wsl-swap.vhdx` | Planned WSL swap file (4GB per desired). |
| `/srv/samwise` | Linux workspace root inside the distro (once registered). |
| `/srv/samwise/core` | Core repo path inside the distro. |

## Ownership (from service locks)

| Owner | Owns | Does not own |
|---|---|---|
| OmniRoute | Governed ingress, routing, event streams, native MCP. Local gateway historically `127.0.0.1:20128`. | Durable cognitive history. |
| YantrikDB | Canonical durable continuity (Engine + Server + MCP). Server HTTP historically port `7438`. | Intent extraction or model routing. |
| OpenClaw | Singular callable interface to Master J; intent extraction; tier-three delegate harness. | Being SAMWISE itself. |
| SAMWISE | Continuity system built on YantrikDB. | Being OpenClaw or OmniRoute. |
| n8n | Deterministic workflows (when deployed). | Canonical memory. |

Authoritative persistent cognitive state: **YantrikDB**. Event stream owner: **OmniRoute**.

## Self-healing workflow (Windows)

1. `bin\inspect.ps1` — capture Windows host and native WSL2 Docker observation.
2. `bin\verify.ps1` — read-only comparison against the frozen desired-state contract.
3. `bin\reconcile.ps1` — update the local checkpoint without WSL shutdown.
4. `bin\benchmark.ps1` — optional measured workload, invoked explicitly with `-Benchmark`.

Do not treat observations, checkpoint, or measurements as YantrikDB substitutes.

## Spelling

Canonical product spelling in locks: **YantrikDB** (not Yantric). Voice/shorthand "Yantric" maps to YantrikDB.
