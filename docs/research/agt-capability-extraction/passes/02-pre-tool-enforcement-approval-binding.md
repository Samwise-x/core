# Pass 02: Pre-tool enforcement and action-bound approval

Date: 2026-10-10. Source inspected; tests NOT EXECUTED.
Pinned AGT: c767f8333f413bd1a93e82836b7aa226280b61ae
Pinned ACS: f2334533651d726b4e9daac170e5116ac3135794
Pinned Agent Hooks: d4890cdfcc074ffacd969ab3668575cdb67a84d9

## Mechanism 1: guarded tool dispatch
AGT Python `policy-engine/sdk/python/agent_control_specification/_orchestration.py:301-370` `AgentControl.run_tool` builds a pre-tool snapshot, evaluates and enforces before executing the tool, applies transformed arguments, then evaluates and enforces the post-tool result. `_adapters/_generic.py:176-218` `guard_tool` wraps the executable. Denial or pre-evaluation failure prevents execution; downstream execution exceptions propagate without post evaluation. `docs/adapter-mediation.md` warns that unwrapped callable references bypass mediation.

## Mechanism 2: approval action binding
`_orchestration.py:390-418,528-542` validates resolver outcomes and requires the original, recomputed and approved action identities to match. Missing resolver, invalid result or identity mismatch denies. `_host.py:398-417` exposes an explicit fail-open timeout option; SAMWISE should not copy it.

## Test anchors
`policy-engine/sdk/python/tests/test_orchestration.py:78-196` (transforms, IDs, denial, downstream failures).
`policy-engine/sdk/python/tests/test_escalation.py:58-115,173-214,252-276` (approval failures, identity mismatch, suspension).
Tests NOT EXECUTED.

## Next
Pass 03: signed identity, delegation narrowing and revocation at the dispatch boundary.

## Exact execution contract
1. `AgentControl.evaluate_intervention_point` in `_orchestration.py:163-189` creates `InterventionPointRequest(point,snapshot,mode)` and forwards it to the runtime client. Invalid request mode or snapshot conversion returns DENY with `host_error:context_invalid`.
2. `AgentControl.run_tool` forms `tool_call:{name,args}` plus optional host-provided `id`; when a SnapshotSource exists, it reserves a tool-call counter before the first await, releasing it on pre-check failure. It invokes `execute(effective_args)` only after successful pre enforcement. Post evaluation uses the effective args and the returned tool value.
3. `AgentControl.enforce` in `_orchestration.py:374-418` permits ALLOW and TRANSFORM in ENFORCE mode; DENY without approval blocks. EVALUATE_ONLY performs no enforcement and must never authorize production effects.
4. The host must route every tool call through the guarded registry. Post-tool denial suppresses a result but cannot undo an effect. Policy mediation errors and downstream callable exceptions are distinct.

## Minimal SAMWISE test-first handoff
Implement at the existing Hooks/AgentSH dispatcher, not a new proxy or policy server:
- RED: DENY or policy-evaluation failure yields zero executions; ALLOW executes once; TRANSFORM changes only validated effective args before execution; post denial never claims rollback.
- RED: no alternate registry route exposes an unguarded callable; EVALUATE_ONLY cannot dispatch an effect.
- RED: absent optional tool-call ID remains absent in the ACS snapshot; blank ID is rejected. AGT `test_orchestration.py:107-155` covers these cases.
- GREEN: adapt existing dispatcher and host snapshot; no new authoritative storage.
- REFACTOR: preserve the above vectors and remove duplicate middleware.

All verification here is source inspection only. No SAMWISE tests were executed.
