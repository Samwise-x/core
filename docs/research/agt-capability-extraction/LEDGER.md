# AGT source-level extraction ledger

Status: research only. Canonical progress for twelve sequential hourly passes. This branch is intentionally isolated from `main`.

## Mission
Extract and evaluate mechanisms already implemented in microsoft/agent-governance-toolkit that can be reused *selectively* in SAMWISE without adding a competing workflow engine or governance authority. Ground every finding in exact source paths, tests/specifications, and pinned upstream commit. No speculation promoted to fact.

## Fixed SAMWISE ownership
- n8n: deterministic workflow execution.
- OmniRoute: event streams, raw observability, trace-to-asset conversion.
- YantrikDB: authoritative durable evidence continuity and admission.
- OpenClaw: intent extraction and singular callable endpoint.
- AgentSH: execution containment; Hooks: deterministic interception.
- Tailscale: mesh. AGT is a reference for extraction, not a new production service.

## Run protocol
At every hourly wake: read this ledger AND existing `passes/` files from this branch, inspect branch state, determine smallest uncompleted pass in order, and inspect upstream at a *recorded commit SHA*. Do not redo completed modules except to resolve an explicit discrepancy. Research may be recursive within the assigned module, but stay within that pass's boundary. Each pass writes `passes/NN-topic.md` with upstream commit, verified file paths and line references, tested contracts, dependencies, failure semantics, matching SAMWISE capability, minimum reusable unit, necessary adaptation, rejected duplication, unanswered questions, and cited evidence. Update ledger by marking completion only AFTER the file exists and is fetchable. If blocked, record blocker and advance to the next independently researchable pass without falsely marking completion. Never make changes to main, D:, WSL, Docker, services, secrets, or runtime. No installation or implementation. Commit all research only on this branch.

### Assigned passes
- [ ] 01: Upstream topology, package distributions, manifests, versions, licenses, specs, conformance suite.
- [x] 02: Agent Control Specification deterministic policy engine, host-enforced fail-closed verdicts, intervention points. Source-traced; tests not executed.
- [x] 03: Identity, signed assertions, SPIFFE/DID, delegation narrowing and revocation. Source-traced; tests not executed.
- [x] 04: Audit chains, Merkle/integrity proofs, immutable receipts, evidence formats and provenance. Source-traced; tests not executed.
- [x] 05: Runtime execution controls, privilege rings, sandbox/containment, kill switches. Source-traced scoped stop gate and termination callback semantics; tests not executed.
- [ ] 06: Intent authorization declare/approve/execute/verify, drift checking and replay.
- [ ] 07: Verification/compliance modules and actual adversarial/conformance tests.
- [ ] 08: MCP/A2A trust gateways and interception, mappings to OmniRoute and Hooks.
- [ ] 09: Lifecycle and recovery: incident handling, saga/retry, failures, SRE integration; exclude competing orchestrator.
- [ ] 10: OpenTelemetry, metrics, trace exporters, OpenObserve/Fast Telemetry/Rolly compatibility with existing observability ownership.
- [ ] 11: Integration seams for n8n, GitHub candidate gate, separately permissioned local WSL verifier, evidence admission; verify real API contracts.
- [ ] 12: Synthesis: deduplicated component extraction matrix, minimum complete AGT-derived subset, dependency graph, evidence coverage, unsolved gaps, sequenced research-to-build handoff.

## Pass files
- 01: Existing placeholder at passes/01-topology-distributions-conformance.md is NOT a completed report; leave unchecked until repaired.
- [02: Pre-tool enforcement and approval binding](passes/02-pre-tool-enforcement-approval-binding.md), source-traced at pinned SHAs; tests not executed. Verified committed report at a99b469a928b90798390457fc0871929cdcaf302.
- [03: Identity delegation and revocation](passes/03-identity-delegation-revocation.md), source-traced at pinned AGT SHA; tests not executed. Existing artifact independently read on this run.
- [04: Audit integrity and session receipts](passes/04-audit-integrity-receipts.md), source-traced at pinned AGT SHA; tests not executed. Verified committed artifact at 1112411928962c9b6ff28d2d49429c85dfa71776.
- [05: Scoped stop gate and termination-result semantics](passes/05-runtime-containment-kill-switch.md), source-traced at pinned AGT SHA; tests not executed. Verified committed report at 598115837078d59e513427514439ae10f14e9d89.

## Non-negotiable
Do not recommend Temporal or another workflow engine. Avoid parallel authoritative stores and extractors. AGT middleware does not by itself create OS-enforced privilege separation. The two-gate workflow and separate verifier authority are already decided; the *enforceable implementation* remains unproven.
