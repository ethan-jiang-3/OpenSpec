# OpenSpec Configuration Guidance

This glossary fixes the terms used by the FAQ material that helps a project choose, design, and maintain `openspec/config.yaml`.

## Runtime Models

**Host Agent**:
The coding agent that invokes OpenSpec while a project is being planned or changed. It is part of the development workflow, not automatically a product runtime actor.
_Avoid_: Runtime Agent, Product Agent

**Runtime Agent**:
A product-time non-deterministic actor authorized to make semantic, content, or path decisions that influence a run.
_Avoid_: Host Agent, Coding Agent

**Hybrid Intelligence Runtime**:
A product runtime in which a Runtime Agent or bounded intelligence node and deterministic components have distinct authority: the former handles bounded semantic work, while the latter owns explicit state, validation, receipts, or verdicts.
_Avoid_: Agentic project (when the authority split has not been established)

**Agent-Controlled Flow**:
A Hybrid Intelligence Runtime in which a Markdown controller or Runtime Agent owns sequencing, semantic routing, and recovery choices; deterministic code supplies gates, records, validation, and bounded diagnostics without becoming a second controller.
_Avoid_: Program-Controlled Flow, code-owned orchestration

**Program-Controlled Flow**:
A Hybrid Intelligence Runtime in which executable code or a graph owns node order, transitions, state, retry, recovery, and action boundaries; intelligence is confined to a named node contract.
_Avoid_: Agent-Controlled Flow, free-form agent orchestration

**Control Boundary**:
A named scope of sequencing, transition, state mutation, or recovery for which one Authority Owner is explicit. Control boundaries can nest, such as a Program-Controlled outer graph containing an Agent-Controlled subflow.
_Avoid_: Whole-project controller (when ownership differs by scope)

**Deterministic Runtime**:
A product runtime whose behavior, state transitions, and authoritative decisions are owned by executable code and explicit data contracts. It can still use an LLM as an input-producing dependency.
_Avoid_: Non-AI project

**Model-as-Input**:
An LLM integration whose output is treated as constrained external input by a Deterministic Runtime; the program, rather than the model, owns the resulting action and truth.
_Avoid_: Runtime Agent

**Authority Owner**:
The component or person whose record or verdict is authoritative for one named decision, state transition, or outcome.
_Avoid_: Consumer, helper
