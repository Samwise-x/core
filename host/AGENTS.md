# Windows substrate agent entry

This deployed directory is the Windows runtime destination. Canonical source
lives in `Samwise-x/core/host/` and is promoted by the accepted two-gate
workflow, pinned to an exact revision.

- **Context:** read [docs/CONTEXT.md](docs/CONTEXT.md) for host ownership and navigation.
- **Topology:** consult `desired.yaml` and `network.yaml`, then observe actual WSL2/Windows state.
- **Observation:** `bin\inspect.ps1` records runtime facts.
- **Verification:** `bin\verify.ps1` observes runtime state read-only; it is not a deployment-success authority.
- **Reconciliation:** `bin\reconcile.ps1` writes a local checkpoint. Benchmarking requires explicit `-Benchmark`.

Runtime evidence and checkpoints never substitute for YantrikDB governed truth.
Preserve `E:\agentos`; migrations require a separate authorized decision.
