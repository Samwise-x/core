# Pass 05 — Scoped stop gate and termination-result truthfulness

Date: 2026-10-10. **SOURCE INSPECTED; TESTS NOT EXECUTED.** Research only; no runtime or production changes.

Pinned source: `microsoft/agent-governance-toolkit@c767f8333f413bd1a93e82836b7aa226280b61ae`. All source/test paths below refer to this commit. Prior completed 02 (guarded dispatch), 03 (identity/revocation), and 04 (audit receipts) were read; 01 is still a placeholder. This pass does not re-inventory or reimplement them.

## Mechanism 1 — Scoped pre-dispatch stop with explicit denied-handler guarantee

**Source definitions:** `agent-governance-golang/packages/agentmesh/kill_switch.go:27-55` declares `KillSwitchScopeKind` and scope constructors (global, agent, capability); `:67-79` validates scope; `:91-110` defines `KillSwitchEvent`, `KillSwitchDecision{Allowed,Scope,Event}`, and history entry; `:175-188` defines an in-memory `KillSwitchRegistry`; `:200-228` implements `Activate`/`Clear`; `:230-260` implements `DecisionFor(agentID,capability)`. The lookup checks active global, then matching agent, then matching capability and returns the **first** active scope's denial; otherwise `Allowed=true`. Empty agent/capability identifiers skip the corresponding scoped checks. `History` at `:262-270` returns a copy of in-memory history, not durable evidence.

**Actual enforcement:** `agent-governance-golang/packages/agentmesh/middleware.go:121-152` `CreateGovernanceMiddlewareStack` adds `KillSwitchMiddleware` **only when** `config.KillSwitches != nil`. `:155-189` `KillSwitchMiddleware` derives capability from `ToolName` (fallback `Action`), calls `registry.DecisionFor`, records structured decision/scope/reason/timestamp metadata, then returns `ErrKillSwitchActive` without invoking `next(operation)` on denial; `:192-200` constructs the denial error. **If the registry is nil, this middleware directly calls the handler**; if the stack was built without a registry, the stop gate is absent. `GovernanceMiddlewareStack.Execute` at `:46-58` composes middleware around the host-provided final handler. The host owns actual effect dispatch and must ensure there is no bypass path.

**Concrete inputs/outputs:** `Activate(CapabilityKillSwitchScope("calculator"),operator_request,"tool maintenance")` -> active scoped event; `DecisionFor("agent-9","calculator")` -> `{Allowed:false,Scope:capability:calculator,Event:...}`; `KillSwitchMiddleware(registry)(handler)(operation)` -> `ErrKillSwitchActive`, **zero handler calls**. Clear that scope -> next decision allows handler. Global stop takes precedence over agent/capability. This is a cooperative **pre-dispatch** gate; it does not terminate running processes or revoke effects already underway. The in-memory registry is neither cross-process consistent nor durable, and a missing registry is permissive.

**Test anchors, NOT EXECUTED:** `agent-governance-golang/packages/agentmesh/kill_switch_test.go:35-74` (agent scope/global priority), `:76-104` (validation and clear), `:142-166` (denial and zero handler invocations), `:168-247` (decision metadata). No SAMWISE tests were run.

## Mechanism 2 — Explicit distinction between termination request and confirmed termination

**Source definitions:** `agent-governance-python/agent-hypervisor/src/hypervisor/security/kill_switch.py:59-72` defines `KillResult{agent_did,session_id,reason,handoffs,compensation_triggered,terminated,...}`; `:85-104` holds registered agent callbacks in memory; `:121-199` `KillSwitch.kill` snapshots callback and substitute, constructs handoff/compensation **status objects**, calls the registered termination callback if any, records `KillResult`, then unconditionally unregisters agent. `:201-235` `_invoke_callback_with_timeout` starts a daemon thread, waits at most `callback_timeout` (default 5 seconds at `:22-25`), and returns `False` on timeout or callback exception. Missing callback yields `terminated=False`. A clean callback return yields `terminated=True`, **but there is no independent process-liveness confirmation**. Timeout leaves a possibly still-running daemon callback. The `HANDED_OFF` and `COMPENSATED` statuses in `:149-171` are assigned from substitute presence; these lines do not invoke a substitute or perform compensation.

**Concrete inputs/outputs:** `register_agent("a1",callback)`; `kill("a1","s1",MANUAL)` -> `KillResult(terminated=True)` only if callback returns within budget without exception; no callback, raising callback, or timeout -> `terminated=False`. Registry removal happens in either case. Thus a successful `kill()` return and even `terminated=True` cannot be interpreted as verified OS process termination.

**Test anchors, NOT EXECUTED:** `agent-governance-python/agent-hypervisor/tests/test_kill_switch.py:187-200` (callback/missing callback), `:204-225` (handoff-status objects), `:239-278` (hung/raising callbacks), `:280-303` (concurrent history). No external process termination tests were run.

## Minimum SAMWISE-owned extraction contract (PROPOSAL, not existing implementation)

**Placement:** Reuse the *decision contract* at the already-owned guarded Hooks dispatch seam, not AGT's middleware stack or mutable in-memory registry. Do not introduce another workflow engine, runtime authority, or evidence store. An independent verifier must establish termination evidence rather than trusting a callback return.

```text
guarded_effect(subject, capability, action, policy_revision):
  require authoritative stop-state projection is available and fresh
  require nonempty authenticated subject and canonical capability
  DENY if global OR subject OR capability stop is active
  DENY on missing/invalid/stale stop state or policy revision
  only then invoke the existing guarded dispatcher exactly once
  emit unadmitted decision/attempt evidence through the existing trace path

request_stop(subject, reason):
  mark stop intent and prevent further guarded dispatch
  request termination via authorized runtime control
  independently observe process/container state
  record {requested, callback_completed, process_verified_stopped} separately
  never claim termination success from callback completion alone
```

**Acceptance tests to implement, NOT EXECUTED:** (1) global, subject, and capability stops each cause zero guarded effect calls; global priority is deterministic; clearing only one scope never overrides another active scope. (2) Missing registry, missing subject/capability, stale projection, unknown scope, and unavailable stop authority all deny; AGT's nil-registry permissive behavior must **not** be copied. (3) An already running effect is never falsely described as stopped by a pre-dispatch decision. (4) A missing/throwing/timed-out termination callback yields `process_verified_stopped=false` until independently observed; a clean callback alone does not satisfy independent verification. (5) Restart or separate-host stop decisions require the same governed stop revision; no in-memory registry can be the authority. (6) Stop request evidence remains unadmitted until existing governed admission accepts it; no duplicate audit store.

**Dependencies and exclusions:** The extracted contracts require a host dispatcher, authenticated subject/capability identity, governed stop-state source, and independent process-state verifier. Do **not** adopt Go `KillSwitchRegistry` as authority, Python `KillSwitch` as process supervisor, its substitute/saga handoff machinery, or AGT orchestration. No new packages are required by this contract.

**Unresolved, source-bounded:** Existing SAMWISE stop-state projection API and refresh/revision semantics; exact OS/process verifier implementation and permissions; atomicity of stop activation versus concurrent dispatch; how a running effect is canceled or contained. Neither inspected AGT mechanism proves those properties.

**Next unexamined capability:** Pass 06, exact intent declaration -> approval -> execution -> verification binding, including drift and replay handling. Pass 01 remains a separate incomplete placeholder.
