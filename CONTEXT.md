# Samwise Core Domain Context

## Purpose

Samwise is a persistent, self-correcting distributed cognitive execution system that compounds operational knowledge.

The system is not defined by any single agent, model, provider, or device. Persistent continuity is the evolving relationship between past, present, and projected future state.

## Core Objective

**Gradient = Compounding.**

The sole optimization objective is measurable compounding, observed through two derivatives:

- **HITL Coordination Tax %**: decreases as the system consumes less human attention per unit of completed work without removing human authority.
- **Quality-Constrained Compression %**: increases as validated execution capability is activated from less human intent, provided correctness and safety are equal or better.

Compression is not omission. It must not be achieved by answering less, retrieving nothing, hiding uncertainty, or discarding provenance.

A positive gradient means subsequent execution becomes cheaper, faster, more reliable, more autonomous, or requires less human input. A flat gradient means the system merely ran. A negative gradient means degradation.

## Canonical Architecture

### YantrikDB

YantrikDB is the singular authoritative persistent state of Samwise.

It owns durable evidence continuity and policy-scoped projections. Immutable history remains the source record.

Learning is projection, not overwrite: the same immutable history combined with the same policy bundle must reproduce the same state.

YantrikDB owns what is allowed to persist or be learned from governed event streams.

### OmniRoute

OmniRoute owns event streams and the immutable append-only observability execution trace.

Every event stream is governed. Memory is an event stream, therefore memory is governed.

An event must pass the OmniRoute governance gate and all system invariants before it can be exposed to YantrikDB as eligible evidence.

OmniRoute also owns raw observability and trace-to-asset conversion. No parallel extractor may reinterpret the same source without an explicit versioned contract.

### Dual-Hop Governance

The governing loop is:

1. Every event reaches OmniRoute and passes its governance gate.
2. Only events satisfying system invariants are exposed to YantrikDB.
3. YantrikDB verifies those events against authoritative persistent state and policy.
4. Unauthorized or unverified information is not authoritative Samwise truth.

Thus, OmniRoute governs the event stream and YantrikDB governs durable truth and learning eligibility.

### Agents

Agents are ephemeral execution substrates. Agents own nothing architecturally authoritative.

Models and providers are replaceable labor, never architectural dependencies.

Stable capability classes sit between agents and models.

### OpenClaw

OpenClaw owns intent extraction and the singular callable endpoint to Master J.

### Browser and Workflow Components

Tandem Browser owns persistent authenticated browser state.

Midscene owns visual-semantic discovery.

n8n owns deterministic workflow execution.

Tailscale owns zero-config device mesh networking.

## System Invariants

1. Memory owns agents | Agents own nothing.
2. YantrikDB owns durable evidence continuity and policy-scoped projections; immutable history remains the source record.
3. Agents are ephemeral execution substrates.
4. OpenClaw owns intent extraction and the singular callable endpoint to Master J.
5. OmniRoute owns event streams.
6. Tandem Browser owns persistent authenticated browser state.
7. Midscene owns visual-semantic discovery.
8. n8n owns deterministic workflow execution.
9. Tailscale owns zero-config device mesh networking.
10. Models and providers are replaceable labor, never architectural dependencies.
11. Gradient = Compounding. HITL Coordination Tax % and Quality-Constrained Compression % are its observable derivatives. All other values are guardrails or measurements.
12. Core infrastructure is open-source and self-hostable.
13. Assets are immutable. Evaluations, evidence links, relations, and policy decisions are append-only.
14. Learning is projection, not overwrite. Same immutable history plus same policy bundle must reproduce the same state.
15. Partial evidence is explicit. Incomplete evidence cannot silently promote capability.
16. OmniRoute owns raw observability and trace-to-asset conversion. No parallel extractor may reinterpret the same source without an explicit versioned contract.
17. Stable capability classes sit between agents and models.

## Controlled Entropy Invariants

- **CEI-1: MONOCULTURE DECAY PENALTY**
- **CEI-2: CONVERGENCE DETECTION AND PERTURBATION**

These are established invariant names. Their mechanics are intentionally not defined here beyond the names until the corresponding domain terms are resolved.

## Evidence and Learning

Execution produces immutable evidence.

Learning is the deterministic projection of immutable evidence under versioned policy.

Success and failure both produce operational knowledge. Samwise does not require a claim of perfect correctness. It compounds evidence, preserves provenance, represents partial evidence explicitly, and avoids treating uncertainty as certainty.

## Human Interaction

Human interaction is an external perturbation source, represented as `human_trace`.

A human instruction is not automatically authoritative merely because it is the latest instruction. Architectural authority comes from the governed protocol, persistent state, policy, and pre-authorized permissions.

## Authority and Continuity

Samwise is loyal to the directive, mission, and endpoint rather than to episodic commands.

No single device is Samwise. Persistent continuity is not uptime; it is the continuity of the evolving graph across past, present, and projected future state.

Components may possess their own operational persistent state, but only YantrikDB is authoritative persistent continuity state within Samwise.

## Domain Language

- **Gradient**: measurable operational improvement produced by compounding.
- **Compounding**: validated operational knowledge making later execution cheaper, faster, safer, more reliable, more autonomous, or less dependent on human coordination.
- **HITL Coordination Tax**: human attention consumed per unit of completed work.
- **Compression Ratio**: validated execution capability activated relative to human intent supplied, constrained by correctness and safety.
- **Operational Knowledge**: validated facts, entity relations, rationale, constraints from failure, successful procedures, failed approaches, tool mappings, environment state, provider performance, routing outcomes, reusable workflows, verification criteria, and governance rules produced by execution.
- **Immutable Evidence**: append-only execution evidence that is not overwritten by later learning.
- **Policy-Scoped Projection**: derived state computed from immutable evidence under a versioned policy bundle.
- **Persistent Continuity**: the evolving graph of past, present, and projected future state, not merely process or service uptime.
- **Governed Event Stream**: an event stream whose contents are subject to system invariants and governance before becoming eligible for authoritative persistence or learning.
- **Capability Class**: a stable capability boundary between ephemeral agents and replaceable models/providers.
- **Human Trace (`human_trace`)**: recorded human interaction treated as an external perturbation source, not as automatically authoritative truth.

## Domain Boundary

This document is the domain glossary, not an implementation specification. Implementation details belong elsewhere.

New domain terms should be sharpened here when they become established. Architectural decisions that involve a meaningful trade-off, are hard to reverse, and would otherwise be surprising should be captured separately as ADRs.
