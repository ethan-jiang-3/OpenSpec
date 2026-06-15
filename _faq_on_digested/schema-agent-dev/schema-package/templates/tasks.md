## 1. Skills

- [ ] 1.1 Write `skills/<name>.md` per design Skill definitions
- [ ] 1.2 Write `skills/<name>.md` per design Skill definitions

## 2. Commands

<!-- Skip this group if design has no Commands section -->
- [ ] 2.1 Write `commands/<name>.md` per design Command definitions

## 3. Tools

<!-- Skip this group if design has no Tools section -->
- [ ] 3.1 Write tool script per design Tool definitions (with executable entry)

## 4. Evals

<!-- Skip this group if design has no Evals section -->
- [ ] 4.1 Write eval case file per design Eval plan
- [ ] 4.2 Run eval cases and verify all pass

## 5. CLI

<!-- Skip this group if design has no CLI section -->
- [ ] 5.1 Implement CLI entry point per design CLI section
- [ ] 5.2 Verify `<name> --help` works and `<name> status --json` returns valid JSON

## 6. Harness Integration

- [ ] 6.1 Copy skill files to target harness skill directory (e.g., `.claude/skills/<name>/SKILL.md`)
- [ ] 6.2 Copy command files to target harness command directory (e.g., `.claude/commands/opsx/<name>.md`)
- [ ] 6.3 Run all eval cases, confirm all pass

## 7. End-to-End

- [ ] 7.1 Walk one real user intent through the full agent chain (proposal → spec → skill → command → tool → eval → CLI)
