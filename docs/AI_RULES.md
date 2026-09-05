# LOOPLAB — AI Engineering Rules

> Read this file at the start of every session. These rules are mandatory for
> all AI-assisted development on LOOPLAB. The PRD/ARCHITECTURE/CHANGELOG at
> `docs/` are the source of truth.

---

## Core Rules

1. **Inspect before editing.** Examine the existing project before changing anything.
2. **Check, don't assume.** Never assume a file, service, folder, RemoteEvent,
   ModuleScript, or system does not exist. Verify first.
3. **Don't rewrite unrelated systems.**
4. **Don't delete functionality** unless explicitly instructed.
5. **Don't replace working architecture** simply because you prefer another one.
6. **Make the smallest safe change** necessary for each milestone.
7. **Keep systems modular** with clear ownership.
8. **Centralize configuration.** No scattered magic values — important config
   lives in a defined centralized location (e.g. `GameConfig`).
9. **Never trust the client** with: currency, XP, rewards, purchases, important
   progression, competitive scores, or other security-sensitive state.
10. **Validate important actions on the server.**
11. **RemoteEvents/Functions must have** server-side validation and reasonable
    rate limiting where appropriate.
12. **No unnecessary dependencies.**
13. **No secrets/credentials/PII** in scripts or the repo.
14. **Preserve save-data compatibility.** Never casually change player data
    schemas without migration/versioning.
15. **Document architecture/API changes** (ARCHITECTURE.md + CHANGELOG.md).
16. **Don't build unrequested features** unless strictly required for the
    current milestone.
17. **Explain large changes before implementing.**
18. **Report after implementation:** what changed, files/objects changed, tests
    performed, known issues, risks, what's next.
19. **On conflict with PRD/architecture: STOP and explain** rather than silently
    choosing a direction.
20. **If unsure, ask** instead of making a destructive assumption.

---

## Milestone Workflow

For every milestone:

1. Read `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/AI_RULES.md`, `docs/CHANGELOG.md`.
2. Inspect the existing project (Studio via MCP + local repo).
3. Explain the current relevant architecture.
4. Propose a concise implementation plan.
5. List files/objects/modules to modify.
6. **Wait for approval** if the change is substantial or potentially destructive.
7. Implement the smallest safe version.
8. Test the implementation.
9. Check for regressions.
10. Update documentation if architecture or behavior changed.
11. Update `docs/CHANGELOG.md`.
12. Summarize: changes, tests, issues, risks, next milestone.

---

## Git / Version Control

- Preferred branches: `main`, `develop`, `feature/<feature-name>`, `hotfix/<feature-name>`.
- Future milestones are developed in feature branches.
- Do not delete/overwrite existing work, reset the repo, force-push, or modify
  unrelated branches.
- Only commit when explicitly requested.