---
status: accepted
---

# WSL-first execution and minimal Windows host boundary

SAMWISE's execution substrate on gtx1660 is WSL2 Ubuntu, rooted in the existing `D:\WSL\samwise-ubuntu` distribution and Linux workspace `/srv/samwise`. Windows remains the hardware, WSL, graphical display, and recovery-access host, not the home for SAMWISE application runtimes. Docker Engine, the singular Tailscale node for this machine, agent runtimes, and browser automation execute inside WSL; Linux Chrome may own authenticated browser state there. Active Linux projects and services use the WSL ext4 filesystem rather than `/mnt/d`. This retains the existing frozen D: namespace and SAMWISE ownership contracts.

This decision supersedes the **Windows-owned Tailscale node and Windows Tailscale Serve/loopback forwarding topology** in both `0002-freeze-tailscale-host-edge-and-service-exposure.md` and `0002-freeze-tailscale-ingress-and-service-port-contract.md`. WSL alone joins the tailnet. Their private-by-default exposure principle and service port reservations remain reference material, not authority to configure Windows-hosted ingress. Actual service exposure is established and verified against the WSL node before activation; no public exposure is implied.

The trade-off is that WSL-based applications and networking no longer depend on a Windows-installed application bridge, while Windows remains responsible for WSL lifecycle, display integration, device drivers, and recovery access. Migrating existing host tools or authenticated browser state is conditional: install and validate the Linux replacement, verify access and recovery, then remove the corresponding Windows application. Do not remove Windows recovery access or change host infrastructure merely to minimize installed software.

This ADR changes the intended boundary, **not the observed deployment state**. Existing configuration, host reconciliation scripts, and operational documents may still describe the earlier topology; their migration and verification are separate implementation work. No application is deemed deployed or migrated by accepting this decision.
