---
status: superseded by ADR-0003
---

# Freeze canonical Tailscale ingress and service port contract

The Samwise host uses one Tailscale node owned by the Windows host. WSL distributions and application containers do not independently join the tailnet unless a later ADR establishes a concrete need. Linux services remain private to the host substrate and are reached through host-local forwarding; Tailscale is the zero-config device mesh and the host's tailnet ingress, not a second application runtime.

Remote service access is tailnet-only by default through Tailscale Serve. Tailscale Funnel is disabled by default and public exposure requires an explicit service-specific decision. MagicDNS is the canonical naming layer. Service backends bind to loopback/private host interfaces and preserve their native ports one-to-one; Samwise does not introduce path multiplexing or a second reverse-proxy namespace merely to reduce visible port count.

Canonical port registry:

- OpenClaw Gateway: TCP/HTTP-WebSocket 18789, tailnet ingress via HTTPS Serve.
- OmniRoute: HTTP 20128, tailnet ingress via HTTPS Serve.
- n8n: HTTP 5678, tailnet ingress via HTTPS Serve when local n8n is deployed.
- YantrikDB wire protocol: TCP 7437, tailnet ingress via Tailscale TCP forwarding only when a native remote client requires it.
- YantrikDB HTTP gateway: HTTP 7438, tailnet ingress via HTTPS Serve.
- OmniConductor hub: HTTP/SSE 7910 when deployed, tailnet ingress via HTTPS Serve.
- Faro/spokesperson: HTTP 7920 when deployed, tailnet ingress via HTTPS Serve only when remote access is required.
- YantrikDB MCP SSE 8420 is optional and is not opened unless that transport is explicitly deployed.

No application service binds directly to the public Internet as part of the baseline. Funnel ports 443, 8443, and 10000 remain unallocated. Tailscale's own transport and peer API ports are implementation/runtime state and are not assigned to Samwise application services.

The current machine may contain legacy Serve mappings or hostnames. Those are observations, not canonical desired state. They are reconciled only after the corresponding backend exists and verifies locally, preventing a stale proxy from being promoted into architecture.
