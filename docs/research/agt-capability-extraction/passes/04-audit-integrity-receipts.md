# Pass 04 — Reproducible audit integrity and session receipt binding

Date: 2026-10-10. **SOURCE INSPECTED; TESTS NOT EXECUTED.** Research-only; no SAMWISE runtime, main branch, or production changes.
Pinned upstream: `microsoft/agent-governance-toolkit@c767f8333f413bd1a93e82836b7aa226280b61ae`. Paths and line ranges below refer to that commit.
Prior completed source investigations: pass 02 (guarded dispatch) and pass 03 (delegation/revocation, artifact exists though ledger is stale). Pass 01 remains a placeholder. This pass does not repeat them.

## Mechanism 1 — Deterministic append-chain plus independently reproducible Merkle inclusion proof

**Exact source**
- `agent-governance-python/agent-mesh/src/agentmesh/governance/audit.py:173-198`: `AuditEntry.compute_hash/verify_hash` hash a sorted-key JSON object containing exactly entry_id, timestamp, event_type, agent_did, action, resource, data, outcome, previous_hash. Digest is lowercase SHA-256 hex.
- `audit.py:288-409`: `MerkleAuditChain._empty_subtree_hash`, `add_entry`, `_add_entry_locked` link each entry to the previous entry hash, update a zero-leaf-padded Merkle tree under a lock, and restore tree/root/entry fields on exceptions. Interior padding is E(k)=SHA256(E(k-1)||E(k-1)), E(0)=64 ASCII zeroes. Internal-node hashing is SHA256 of concatenated **hex hash strings**, not concatenated raw digest bytes.
- `audit.py:421-479,486-559`: `_rebuild_tree_locked` independently rebuilds padded tree; `_snapshot` takes membership/root under one lock; `_proof_snapshot` returns (entry, sibling hash/direction pairs, root) from the same locked state; `verify_proof` folds left/right sibling strings to the root; `_verify_entries` checks each entry hash and previous_hash continuity.
- `audit.py:595-654,740-810`: `AuditLog.log` atomically updates in-memory indexes/tree before calling optional `sink.write(entry)`; `verify_integrity`, `verify_snapshot`, `get_proof`, `export` expose chain/proof/root.

**Concrete execution**: caller supplies `event_type, agent_did, action, resource?, data?, outcome?, policy_decision?, trace_id?, ...` -> `AuditLog.log` constructs `AuditEntry` -> locked append computes previous_hash and entry_hash -> updates Merkle path/root and indexes -> optional external sink write -> returns entry. For verification, capture root and entry/proof from one snapshot; independently recompute covered leaf hash, previous-hash continuity, and padded Merkle root; check sibling directions against the anchored root. A failed in-memory tree/hash update rolls back and propagates the exception. **A failed external sink write occurs after the in-memory append, with no corresponding rollback in `AuditLog.log`; durable admission is NOT atomic in this implementation.** A single-entry `MerkleAuditChain.get_proof` returns an empty list; `AuditLog.get_proof` returns None when proof is empty (`audit.py:767-785`), so consumers must handle singleton chains explicitly.

**Critical limits, verified from source**:
1. `AuditEntry.compute_hash` omits `policy_decision`, `matched_rule`, `policy_version`, `arguments_hash`, `approver_did`, `issued_at`, `completed_at`, `trace_id`, `session_id`, `target_did`, and environment fields. `audit.py:56-160` explicitly labels several fields NOT covered in spec v1.0. An intact chain/root therefore does **not** authenticate those fields.
2. `_snapshot` copies the entry **list**, not its mutable `AuditEntry` objects; concurrent object mutation after lock release is not protected by the snapshot contract. Use immutable canonical event bytes for independent verification.
3. A locally recomputed Merkle root without an independently trusted previously committed root does not prove history was not replaced/truncated. `AuditLog` alone is an in-memory container, not a governed append-only durable store.

**Source test anchors, NOT EXECUTED**: `agent-governance-python/agent-mesh/tests/test_merkle_audit_root_reproducible.py:27-159` independently recomputes roots for sizes 1..32, 100, 1000, verifies proofs and tamper-different roots; `:237-382` tests snapshot locking and rollback under injected node/hash failures; `tests/test_audit_reader_consistency.py:38-141,145-210` tests concurrent read/write snapshot/proof coherence. No SAMWISE admission or cross-process tests were run.

## Mechanism 2 — One-snapshot, content-bound session receipt construction

**Exact source**
- `agent-governance-python/agent-mesh/src/agentmesh/governance/trace_sink.py:62-141`: `session_to_trust_record` takes one `audit_log._chain._snapshot()`; `_snapshot_to_trust_record` computes SHA256 over compact, sorted-key JSON serialization of **all** `AuditEntry.model_dump(mode="json")` objects, records count, policy bundle hash, subject, and a software-only runtime measurement SHA256(ASCII Merkle root).
- `trace_sink.py:144-231`: `TRACEAuditSink.emit` rejects absent/empty log, skips subject not starting `did:` or `spiffe://`, loads `agentrust_trace` key, signs via `sign_record`, validates via `TrustRecord.model_validate`, writes signed JSON to a local file, and returns path. Missing package raises RuntimeError; signing/write exceptions are not swallowed. Package requirement shown at lines 198-204: `agentrust-trace>=0.5.1,<0.6.0`. No independent signature-verification path was traced in this pass.
- `trace_sink.py:97-135`: runtime is explicitly `software-only`; fallback build provenance digest is derived from Merkle root, not a measured binary; `appraisal.status` is hard-coded `affirming` and `transparency` is `None` (no transparency receipt/anchor). **Do not treat either as independent attestation.**
- `tests/test_audit_reader_consistency.py:155-210,255-335` covers root consistency across append races and signed-record emission callback ordering outside the chain lock. Tests NOT EXECUTED.

**Concrete execution**: captured (entries, root) -> canonical full-entry JSON digest and count -> receipt fields (subject, policy hash, software-only measurement, transcript digest) -> sign/validate -> write local JSON. This is a reusable **receipt schema/serialization contract**, not an independently anchored proof or proof of policy compliance. Hashing all serialized entries covers fields excluded from `AuditEntry.compute_hash`, **provided** the transcript digest itself is authenticated and the verifier receives identical canonical entry bytes.

## Minimal SAMWISE-owned extraction contract (proposal, not a claim of existing implementation)

**Placement**: OmniRoute supplies raw trace-to-asset identifiers; YantrikDB alone admits immutable evidence and governed projections. Reuse only (a) canonical event digest + previous-digest chain and independently recomputable Merkle proof contract and (b) consistent-snapshot transcript receipt fields. Do **not** install AGT AuditLog, its optional mutable sinks, TRACE service, or another authority. This is a verification contract, not a new orchestration service.

```text
propose_receipt(events, prior_anchor, policy_revision, trace_asset_id):
  freeze each event into canonical bytes under a versioned schema
  require covered fields include action digest, outcome, policy revision, principal,
          approval binding, timestamps and trace-asset digest
  leaf[i] = SHA256(domain || canonical_event[i] || previous_leaf_digest)
  root = MerkleRoot(versioned_padding_and_hex_encoding, leaf[])
  receipt = {schema_version, event_count, prior_anchor, root,
             transcript_digest: SHA256(canonical_event_sequence),
             trace_asset_id, policy_revision}
  return receipt as UNADMITTED evidence
verify_before_admission(receipt, events, trusted_previous_anchor):
  recompute every covered leaf, continuity, transcript digest, root and count
  reject missing/mismatched prior anchor, malformed proof, incomplete bytes or unknown schema
  submit verified evidence to YantrikDB governed admission
  do not call receipt durable/authoritative before admission succeeds
```

**Acceptance tests to implement (NOT EXECUTED)**:
1. Deterministic roots for 1, 2, 5, 6, 9, 13, 20, 100 and 1000 identical frozen events; independent implementation must agree on root and inclusion paths. Singleton proof must be valid with empty sibling list.
2. Mutating **any** security-critical receipt field (especially `policy_version`, `arguments_hash`, `approver_did`, `issued_at`) changes canonical digest and fails verification; demonstrate AGT v1.0 leaf hash alone does not catch those mutations.
3. Tamper, reorder, truncate, duplicate, or omit events; wrong prior anchor, stale policy revision, and mismatched trace-asset digest => reject, no admission.
4. Concurrent append while snapshotting must never yield an entry count/root/transcript mismatch; mutation of returned event objects after capture must not alter frozen receipt bytes.
5. Inject sink/admission failure after local receipt construction: do not report durable success; retry with same idempotency key must not duplicate admitted evidence.
6. Signature verification must reject untrusted key, altered payload, wrong subject and absent independent anchor; a hard-coded `affirming` appraisal cannot satisfy verification.

**Unresolved, bounded**: actual YantrikDB admission API/schema, independent anchor signing/storage, canonical byte encoding/versioning across languages, AGT TRACE verifier behavior and trust-key lifecycle, crash-consistent persistence/atomicity. No claim that AGT implements these end-to-end.

**Next unexamined seam**: Pass 05, actual runtime containment/kill-switch enforcement call paths and failure behavior. Do not re-investigate hash chains, identity, or ACS dispatch.
