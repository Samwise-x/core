---
status: accepted
---

# WSL-first execution and minimal Windows host boundary

SAMWISE executes its Linux services, agents, browser automation, development tooling, and mesh networking inside the `samwise-ubuntu` WSL2 distribution. Windows remains the hardware, WSL, graphical-display, and recovery host; it is not an application runtime or the Tailscale ingress node for SAMWISE. This keeps authenticated browser state and agent/service execution together, reduces Windows-side dependencies and cross-boundary control paths, and preserves a minimal host recovery surface.

The existing `D:\\WSL\\samwise-ubuntu` storage and `D:\\Samwise\\host` reconciliation namespace remain governed by ADR-0001; Linux repositories and workloads belong under `/srv/samwise` in the ext4 filesystem. The single Tailscale node for this machine runs **inside WSL**, not Windows, superseding the Windows-owned node and Windows Serve topology specified in both ADR-0002 records. Tailnet exposure stays private by default: only verified, authorized backends receive the service mappings they require. Existing service port reservations remain references until validated against the WSL-local topology.

Native Linux Chrome owns its profile, cookies, and authenticated sessions for SAMWISE browser work. WSLg may use Windows for graphical display without moving Chrome's automation/control runtime onto Windows. Docker Engine, source-control clients, agent tooling, and service dependencies likewise run in WSL as required; Windows retains only what the OS, hardware, WSL, remote recovery, or an independently justified host function requires.

Migration proceeds by verifying each Linux replacement and its state, access, and recovery path **before** removing a Windows installation. Deployment scripts, operational documentation, and runtime verification must reflect the actual WSL topology. A version-controlled change is complete when its configured behavior is verified and its affected operational documentation is reconciled. This ADR records the boundary and rationale; it does not assert that every component has been migrated or deployed.

**Supersedes:** `docs/adr/0002-freeze-tailscale-host-edge-and-service-exposure.md` and `docs/adr/0002-freeze-tailscale-ingress-and-service-port-contract.md` for Tailscale node ownership, ingress topology, and any Windows-specific exposure assumption.
