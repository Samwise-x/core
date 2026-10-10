---
status: superseded by ADR-0003
---

# Freeze Tailscale host edge and Samwise service exposure contract

Samwise uses the Windows host as the single Tailscale node for this machine. Tailscale does not run inside WSL2. This follows Tailscale's current Windows/WSL2 guidance: running Tailscale on both Windows and WSL2 can break encrypted traffic because Tailscale packets cannot be nested inside Tailscale packets. The canonical node name is `gtx1660`; service configuration uses its MagicDNS name rather than hard-coding the current 100.x address.

The host edge is private-by-default. Linux services run inside WSL2/Docker and publish to Windows loopback only. Tailscale Serve, running on Windows, is the only canonical tailnet ingress from this machine into those loopback-published services. Tailscale Funnel is disabled by policy for Samwise control, memory, routing, browser, and workflow surfaces unless a later explicit decision authorizes a specific public endpoint. Subnet routing and exit-node behavior are not part of this host contract.

Canonical service ports are:

| Surface | Canonical port | Exposure |
| --- | ---: | --- |
| OpenClaw gateway | 18789/tcp | Tailnet HTTPS via Tailscale Serve when deployed |
| OpenClaw sandbox/bridge | 18790/tcp | Loopback/private support surface; tailnet exposure only if a deployed OpenClaw feature explicitly requires it |
| OmniRoute | 20128/tcp | Tailnet HTTPS via Tailscale Serve when deployed |
| OmniConductor hub | 7910/tcp | Private service-to-service; tailnet only when a remote peer requires it |
| Faro spokesperson | 7920/tcp | Private service-to-service; dashboard reaches it through OmniRoute's server-side proxy, not directly from browsers |
| YantrikDB wire protocol | 7437/tcp | Private raw TCP; tailnet only for explicitly authorized remote clients/peers |
| YantrikDB HTTP gateway | 7438/tcp | Private HTTP/HTTPS; tailnet only for explicitly authorized remote clients/peers |
| YantrikDB cluster transport | 7440/tcp | Cluster-internal; never general user ingress |
| YantrikDB MCP network transport | 8420/tcp | Optional authenticated MCP HTTP/SSE surface; no exposure unless network MCP transport is explicitly deployed |
| n8n local instance | 5678/tcp | Reserved only if n8n is deployed locally; no local exposure is implied while n8n is hosted elsewhere |
| Tandem Browser | none frozen | No inbound tailnet port until a deployed requirement proves one is necessary |
| Midscene | none frozen | No inbound tailnet port until a deployed requirement proves one is necessary |

For HTTP surfaces the deployment pattern is `container -> WSL/Docker host publish 127.0.0.1:<port> -> Windows localhost forwarding -> Tailscale Serve -> tailnet`. Backends must not bind directly to a LAN-facing Windows interface merely to make them reachable through Tailscale. For raw TCP surfaces such as YantrikDB's wire protocol, Tailscale Serve TCP forwarding may be used from the same canonical port to `tcp://127.0.0.1:<port>` only when remote access is actually required.

The Tailscale transport listener is Tailscale-owned infrastructure, not a Samwise application port. UDP 41641 observed on the host remains managed by Tailscale and is not assigned to any Samwise service.

Access control applies independently of service binding. No wildcard tailnet access grant is canonical for Samwise control/data surfaces. Before any Serve mapping is activated, the applicable tailnet policy must explicitly authorize the intended source identities/devices for that destination and port. A missing or unverified policy is deployment drift, not permission by implication.

At the time of this decision, the live Windows node runs Tailscale 1.102.2 with MagicDNS enabled, no advertised routes, no exit node, no Tailscale SSH server, and no advertised tags. Existing Serve entries on 18789, 20128, and 5678 reference an obsolete host name and have no live local backend listeners; they are pre-contract drift and are not adopted as canonical state.

The service mappings above are reservations and ownership assignments, not instructions to expose absent services. Serve entries are created only when the corresponding backend is deployed and verified, then removed when that backend is retired.
