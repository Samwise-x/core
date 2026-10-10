# Pass 03 — Identity-bound delegation and revocation at dispatch

Date: 2026-10-10. **SOURCE INSPECTED; TESTS NOT EXECUTED.** No SAMWISE runtime inspection or changes.
Pinned upstream: `microsoft/agent-governance-toolkit@c767f8333f413bd1a93e82836b7aa226280b61ae`. All paths below are relative to this commit.
Pass 02's pre-tool enforcement is already documented; this pass examines only the identity/authorization inputs it would need.

## Mechanism 1 — Validate live parent lineage before allowing delegated capability

**Exact implementation**

- `agent-governance-python/agent-mesh/src/agentmesh/identity/agent_id.py:204-232`: `AgentIdentity.sign(bytes)` produces a base64 Ed25519 signature; `verify_signature(bytes, str)` verifies against the identity's public key and returns `False` on invalid/malformed signature (or raises for signing without a private key).
- Same file `:237-302`: `AgentIdentity.delegate(name, capabilities, ...)` rejects depth >= 10, a delegated literal `*`, and any capability not literally present in the parent's list. It creates a new child keypair/DID, copies the sponsor, and sets `parent_did` and incremented `delegation_depth`. This **does not sign a delegation assertion**; the docstring's cryptographic-enforcement claim is not implemented by this method.
- Same file `:339-345,421-480`: `is_active()` checks status and expiry; `verify_delegation_chain(identity, registry)` recursively resolves each parent, requires the parent active, child capabilities contained by parent, depth exactly parent+1, and no cycles. Missing parent or inactive parent => `False` **when a registry is supplied**. Without a registry, `:456-458` accepts any delegated leaf with positive depth, so registry-free validation is **not authorization**.
- Same file `:482-512`: `get_effective_capabilities(registry)` intersects capabilities along known ancestors; missing registry/ancestor returns a partial leaf or truncated intersection, **not a fail-closed verdict**.
- `agent-governance-python/agent-mesh/src/agentmesh/identity/delegation.py:107-158,237-309`: `DelegationLink.verify_capability_narrowing`, `ScopeChain.add_link`, and `ScopeChain.verify` enforce depth, link continuity, hashes, and narrowing. **Signature verification is optional**: `_verify_link_signature` at `:264-270` returns `True` when parent identity is missing. `verify()` also returns success on an empty link list (`:279-280`). `DelegationLink.compute_hash` at `:134-147` omits expiration, parent capability list, signature, and most user-context fields; a hash is not an authenticated grant.
- `agent-governance-python/agent-mesh/src/agentmesh/trust/capability.py:422-504`: `CapabilityRegistry.grant(..., require_grantor_capability=False)` defaults to skipping grantor authorization; `True` checks grantor's live scope and every resource ID, rejecting unauthorized delegation with `PermissionError`. `:507-526` `check(agent_did, capability, resource_id)` returns `False` for unknown agents or absent valid grants.

**Actual call and failure contract**: trusted caller resolves authoritative parent identity -> verifies parent status and entire parent chain -> checks requested capability/resource against the parent's current grant -> narrows to child -> dispatch layer checks effective authorization **again at effect time**. The source supplies individual primitives, **not a verified end-to-end wiring of these checks into ACS PRE_TOOL_CALL**. `AgentIdentity.delegate` raises `ValueError` for escalation, depth, or wildcard; `verify_delegation_chain` returns `False` for missing/inactive parents or cycles only when registry is supplied; `CapabilityRegistry.grant` rejects unauthorized grantors only with `require_grantor_capability=True`.

**Source test anchors (NOT EXECUTED)**: `agent-governance-python/agent-mesh/tests/test_spec_identity_trust_conformance.py:781-810` covers narrowing, unknown capability, wildcard, depth; `:1210-1233` parent traversal and cycle; `tests/test_identity.py:130-160` delegation; `:344-398` explicitly tests that ScopeChain accepts invalid signatures when the parent identity is unknown, but rejects them when known. No test of a SAMWISE dispatch integration was run.

## Mechanism 2 — Revocation checked independently of cached signature verification

**Exact implementation**

- `agent-governance-python/agent-mesh/src/agentmesh/identity/revocation.py:17-38,40-117`: `RevocationEntry(agent_did, revoked_at, reason, revoked_by, expires_at)`; `RevocationList.revoke` adds a DID, `is_revoked` returns a boolean and expires temporary entries, `unrevoke` removes one. `:137-169` saves/loads mutable JSON when configured; this is **not append-only evidence** and does not prove mesh-wide propagation.
- `agent-governance-python/agent-mesh/src/agentmesh/identity/agent_id.py:304-345,586-599`: `AgentIdentity.revoke` changes status; `IdentityRegistry.revoke` recursively revokes registered descendants; returns `False` for missing identity. This recursion is in-memory over registered children; do not infer distributed invalidation.
- `agent-governance-python/agent-mesh/src/agentmesh/trust/cards.py:47-57,59-137`: `TrustedAgentCard` signs deterministic card fields; `verify_signature(identity_registry=...)` uses the registry's public key and rejects unknown DIDs. Without a registry, it accepts a **self-attesting embedded key**, proving possession of that key, not authoritative DID ownership.
- Same file `:269-283,299-350`: `CardRegistry.register` checks card signature; `CardRegistry.is_verified(agent_did)` checks `revocation_list.is_revoked` **before consulting its signature-verification cache**. Revoked DID => `False` and cached entry removal; unknown card => `False`. Revocation is not enforced by this method if no revocation list was supplied. The registry must also be backed by an authoritative identity registry to avoid self-attestation.
- `agent-governance-python/agent-mesh/src/agentmesh/trust/capability.py:528-542`: `CapabilityRegistry.revoke_all_from(grantor_did)` iterates scopes and invalidates direct grants issued by that grantor; this is distinct from descendant identity revocation.

**Actual call and failure contract**: authenticated DID/key binding -> authoritative identity registry lookup -> check current revocation/status -> validate requested capability and lineage -> allow or deny before execution. A revoked DID is denied by `CardRegistry.is_verified` even if signature verification was previously cached. No revocation-list attachment => the card registry has no revocation veto; no identity registry => embedded-key self-attestation can pass; no shared authoritative store => no demonstrated cross-host revocation consistency.

**Source test anchors (NOT EXECUTED)**: `agent-governance-python/agent-mesh/tests/test_revocation_rotation.py:58-88` checks revoked cards fail and changing revocation list clears cache; `tests/test_credential_lifecycle.py:249-261` checks child status after parent revocation; `tests/test_revocation.py:34-116` covers temporary expiry, file persistence, and overwrite. No mesh propagation latency or cross-process test was executed.

## Minimum SAMWISE-owned extraction contract

**Placement (proposal, not an assertion that this code exists today):** feed these checks into the already-owned pre-tool Hooks interception decision; derive current identity, lineage, and revocation state from YantrikDB's governed policy projection rather than installing AGT's mutable `RevocationList`, `IdentityRegistry`, `CapabilityRegistry`, SPIFFE server, or a second authoritative store. No changes were made.

```text
authorize_delegated_effect(subject_did, requested_capability, resource, action_digest, policy_revision):
  identity = authoritative_identity(subject_did, policy_revision)
  DENY unless identity exists, status == active, not expired, and its key is trusted
  chain = resolve_complete_parent_chain(identity, policy_revision)
  DENY unless chain reaches trusted root, is acyclic, all ancestors active,
              depths contiguous, every edge authenticated, each child scope <= live parent scope
  DENY unless requested_capability/resource is granted in effective intersection
  DENY if any relevant identity or grant is revoked at authorization time
  bind ALLOW to subject_did + requested_capability + resource + action_digest + policy_revision
  only guarded host dispatcher may execute the bound action
```

**Acceptance vectors to implement and run (NOT EXECUTED)**

1. Child requests capability absent from parent => DENY and zero tool invocations; parent with `read:data` cannot delegate `write:data`.
2. Missing parent, missing identity registry, cycle, wrong depth, inactive/expired parent, invalid signature, or self-attesting unregistered card => DENY and zero invocations. In particular, do **not** adopt `ScopeChain`'s optional signature behavior.
3. Parent revoked after child creation, or child revoked after prior successful cached verification => next pre-tool decision DENY. An old ALLOW cannot authorize a later changed action or policy revision.
4. Unknown grantor, unauthorized grantor, resource outside grantor's scope, or unrecognized resource => DENY; never use `require_grantor_capability=False` for untrusted grants.
5. Valid signed lineage with strict monotonic scope narrowing, live nonrevoked ancestors, exact action binding, and valid resource => exactly one guarded execution; tests must distinguish policy decision from actual tool invocation.
6. Re-run same vectors after process restart and across separate verifier/dispatcher contexts against the same governed revision; a stale local cache cannot override revocation. This is a **required future SAMWISE test**, not an upstream-proven property.

**Explicit exclusions / unresolved source gaps**: `ScopeChain`'s hash-only or optional-signature proof is not sufficient for authorization; card self-attestation is not trusted identity; mutable JSON revocation list is not durable governed evidence. Source inspection did **not** establish signed end-to-end delegation grants, authenticated sponsor verification, revocation propagation SLA, a direct ACS dispatch hook consuming these identity decisions, or existing SAMWISE APIs for authoritative identity lookup. Those seams must be verified, not assumed.

**Next unexamined seam:** Pass 04, cryptographic integrity of audit receipts and append-only/tamper-evident evidence, including exact admission boundary; avoid redoing identity or ACS orchestration.
