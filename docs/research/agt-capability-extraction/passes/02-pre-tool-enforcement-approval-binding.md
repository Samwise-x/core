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
