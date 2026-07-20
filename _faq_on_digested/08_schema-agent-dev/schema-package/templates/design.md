## Context

<!-- Background, target harness, constraints. Check openspec/specs/ for current agent capabilities. -->

## Goals / Non-Goals

**Goals:**
<!-- What this design aims to achieve -->

**Non-Goals:**
<!-- What is explicitly out of scope -->

## Skills

<!-- For each capability in specs, define the implementing skill. Skip if this change doesn't add/modify skills. -->

- **Skill name**: <name> → `skills/<name>.md`
- **Trigger**: <when the agent should activate this skill>
- **Steps**:
  1. <step>: <what it does, input, output>
  2. ...
- **Error handling**: <per scenario——missing input / tool failure / permission denied>
- **Collaborates with**: <other skills, how they interact>

## Commands

<!-- Slash-command design. Skip if this change doesn't need user-facing commands. -->

| Command | Skills orchestrated | Arguments | User intent |
|---|---|---|---|
| `/agent:<verb>` | skill-a → skill-b | `$ARGUMENTS` | <one-liner> |

## Tools

<!-- Runtime tools/scripts. Skip if not needed. -->

- **Tool name**: <name> → `tools/<name>.<ext>`
- **Input schema**: <JSON Schema or structured description>
- **Return format**: <JSON structure / exit code>
- **Side effects**: <file I/O, network calls, state changes>
- **Harness adapter notes**: <any differences between OpenSpec / Claude Code / Cursor>

## Evals

<!-- Behavior test plan per skill. Skip if not needed. -->

- **Skill**: `skills/<name>.md`
  - **Normal**: <input> → <expected output>（assert: `grep '...' output.md`）
  - **Boundary**: <edge case input> → <expected behavior>（assert: `test -f ...`）
  - **Refusal**: <out-of-scope input> → <expected refusal message>（assert: `grep -i '...' output.md`）

## CLI

<!-- CLI surface design. Skip if this agent is not a CLI tool. -->

- **Binary**: `<name>`
- **Subcommands**:

| Subcommand | Maps to skill | Flags |
|---|---|---|
| `<name> <verb>` | `skills/<name>.md` | `--<flag>` |

- **Status API**: `<name> status --json` → `{ "skills": N, "ready": bool }`

## Decisions

<!-- Key technical choices with rationale (why X over Y?). Include alternatives considered. -->

## Risks / Trade-offs

<!-- Known limitations, things that could go wrong. Format: [Risk] → Mitigation -->

## Migration Plan

<!-- Steps to deploy, rollback strategy -->
