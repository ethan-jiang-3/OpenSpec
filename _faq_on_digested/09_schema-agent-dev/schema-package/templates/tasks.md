## 1. Skills

- [ ] 1.1 Write `skills/<name>.md` per design Skill definitions — verify: inspect the file against the skill contract
- [ ] 1.2 Write `skills/<name>.md` per design Skill definitions — verify: run its normal and refusal eval prompts

## 2. Commands

<!-- Skip this group if design has no Commands section -->
- [ ] 2.1 Write `commands/<name>.md` per design Command definitions — verify: invoke it with representative arguments

## 3. Tools

<!-- Skip this group if design has no Tools section -->
- [ ] 3.1 Write tool script per design Tool definitions (with executable entry) — verify: run the tool contract tests

## 4. Evals

<!-- Skip this group if design has no Evals section -->
- [ ] 4.1 Write eval case file per design Eval plan — verify: lint or parse the eval fixture
- [ ] 4.2 Run eval cases — verify: all expected assertions pass

## 5. CLI

<!-- Skip this group if design has no CLI section -->
- [ ] 5.1 Implement CLI entry point per design CLI section — verify: `<name> --help` exits successfully
- [ ] 5.2 Implement status output — verify: `<name> status --json` returns valid JSON

## 6. Harness Integration

- [ ] 6.1 Copy skill files to target harness skill directory (e.g., `.claude/skills/<name>/SKILL.md`) — verify: the harness lists the skill
- [ ] 6.2 Copy command files to target harness command directory (e.g., `.claude/commands/opsx/<name>.md`) — verify: the harness lists the command
- [ ] 6.3 Run all eval cases — verify: all expected assertions pass

## 7. End-to-End

- [ ] 7.1 Walk one real user intent through the full agent chain — verify: observed output matches the expected end-to-end outcome
