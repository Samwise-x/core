---
status: accepted
---

# Freeze canonical Windows/WSL host substrate layout

Samwise's Windows host substrate uses a minimal D: layout that separates physical WSL storage from host-side reconciliation artifacts, while preserving the canonical ownership model in `CONTEXT.md`: YantrikDB remains the singular authoritative persistent state, OmniRoute owns event streams and raw observability governance, and n8n owns deterministic workflow execution. Host files are observations, checkpoints, measurements, and desired-state declarations only; they are not parallel Samwise truth.

```text
D:\
├── WSL\
│   ├── samwise-ubuntu\
│   │   └── ext4.vhdx
│   └── wsl-swap.vhdx
└── Samwise\
    └── host\
        ├── desired.yaml
        ├── observations\
        │   └── <timestamp>.json
        ├── raw-observability.jsonl
        ├── checkpoint.json
        ├── measurements.jsonl
        └── bin\
            ├── inspect.ps1
            ├── reconcile.ps1
            ├── verify.ps1
            └── benchmark.ps1
```

Active Linux repositories and Linux-heavy workloads live inside the WSL ext4 filesystem, rooted at `/srv/samwise/`, rather than under `/mnt/d`. Service directories under `/srv/samwise/` are created only when the corresponding service is actually deployed. Docker-owned storage is not pre-created or modeled as Samwise state; Docker creates and owns its own storage image, and any supported relocation is configured and verified after installation.

The host artifact semantics are fixed as follows:

- `desired.yaml` is the host reconciliation target, not authoritative Samwise state.
- `observations/*.json` are machine observations, not Samwise truth.
- `raw-observability.jsonl` is raw execution and measurement trace subject to OmniRoute governance before it can become eligible evidence.
- `checkpoint.json` is local operational continuation state, not persistent cognitive continuity.
- `measurements.jsonl` contains guardrails and measurements, not the optimization objective.
- The optimization objective remains Gradient = Compounding, observed through HITL Coordination Tax % and Quality-Constrained Compression %.

Initial host measurements are established empirically from a clean deployment and then used to derive regression thresholds. The frozen topology is not expanded speculatively; new directories or abstractions are added only when a deployed capability requires them.
