## Why

<!-- Explain the motivation. Who is this agent for? What problem does it solve? Why now? -->

## What Changes

<!-- Describe what will change. New agent capabilities, modifications, or removals. -->

## Capabilities

### New Capabilities
<!-- Capabilities being introduced. Replace <name> with kebab-case identifier. Each creates specs/<name>/spec.md -->
- `<name>`: <brief description of what this capability covers>

### Modified Capabilities
<!-- Existing capabilities whose REQUIREMENTS are changing. Use existing spec names from openspec/specs/. -->
- `<existing-name>`: <what requirement is changing>

## Constraints

<!-- Hard boundaries the agent MUST NOT cross. -->

**Must NOT do:**
- <constraint>: <reason——compliance, safety, business rule>

**Must refuse:**
| Input type | When to refuse | Refusal message |
|---|---|---|
| <out-of-scope request> | <trigger condition> | "<refusal template>" |
| <safety/compliance risk> | <trigger condition> | "<refusal template>" |

## Baseline Prompt

<!-- System-prompt equivalent, distilled from Why, Capabilities, and Constraints.
     Downstream harnesses inject this directly. -->

You are <Agent Name>, a <role>.
Your users are <user description>.
You are authorized to: <capability summary>.
You must NOT: <constraint summary>.
When you receive <refusal-trigger type>, you MUST reply: "<refusal message>".
Your default output format: <output contract——concise/structured/adaptive, target audience>.

## Impact

<!-- Affected harnesses, tools, existing skills, dependencies -->
