# Windows substrate context

`D:\Samwise\host` is the deployment destination for the host substrate.
The canonical source is `Samwise-x/core/host`; working checkout:
`/srv/samwise/core` on the WSL2 ext4 filesystem.

## Ownership

Windows owns disk placement, WSL registration, display integration, and recovery access.
The `samwise-ubuntu` distribution is the intended owner of Tailscale,
the Linux Docker Engine, and Linux workloads under accepted ADR-0003.
Docker Desktop is not a dependency.

`desired.yaml` and `network.yaml` express the approved target contracts.
Inspect actual state before executing. When observed state and frozen
contracts disagree, report the discrepancy for the topology decision.
The host verifier reports drift without changing the running machine.

`observations/`, `raw-observability.jsonl`, `measurements.jsonl`,
and `checkpoint.json` are host evidence/continuation artifacts; neither
these nor GitHub issues are authoritative Samwise durable continuity.

## Where to look

- Host vocabulary: [GLOSSARY.md](GLOSSARY.md).
- WSL clean export and recovery procedure: [wsl-baseline.md](wsl-baseline.md).
- Canonical domain invariants: Core `CONTEXT.md`.
- Host layout: Core accepted ADR-0001.
- Tailscale ingress and service-port ownership: Core accepted ADR-0003.
- Source and independent deployment gates: Core Wayfinder issues and host README.

Inspection can be performed at any time. Apply reconciliation and
benchmarking only when writing operational evidence is authorized.
