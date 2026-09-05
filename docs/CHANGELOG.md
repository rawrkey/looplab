# LOOPLAB — Changelog

All notable changes to LOOPLAB are documented here. One entry per milestone.

Format: `## [Unreleased]` / `## [Milestone] — YYYY-MM-DD`

---

## [Milestone 0] — Project Foundation — 2026-09-05

### Local repository
- Created `Projects/looplab` as the LOOPLAB project root.
- Initialized Git repository (`main` + `develop` branches).
- Added `docs/` Markdown documentation as the source of truth.

### Documentation
- `docs/PRD.md` — product requirements (vision, concept, audience, loop,
  activities, progression, XP/currency, cosmetics, social, parties,
  recommendation, onboarding, daily challenges, live events, monetization,
  analytics, retention, performance, security, MVP scope, excluded features,
  launch requirements, live-ops, definition of done).
- `docs/ARCHITECTURE.md` — target modular architecture (server/shared/client
  split, services, data flow, player data, activity lifecycle, rewards,
  remotes, recommendation, economy, monetization, analytics, security, error
  handling, performance, save-data versioning, how to add mini-games).
- `docs/AI_RULES.md` — the 20 mandatory AI development rules + milestone
  workflow + git conventions.
- `docs/CHANGELOG.md` — this file.

### Roblox Studio scaffolding (non-destructive)
The place was a clean SuperTemplate baseplate (no scripts/folders/remotes/UI).
Created scaffolding only — no gameplay code:
- `ServerScriptService.LOOPlab.Server.Services` (Folder, placeholder)
- `ReplicatedStorage.LOOPlab` (Folder) → `Shared`, `Configuration`, `Remotes`
- `ReplicatedStorage.LOOPlab.Configuration.GameConfig` (ModuleScript) —
  centralized configuration module (version constant + placeholder config)
- `StarterPlayer.StarterPlayerScripts.LOOPlab.Client` (Folder, placeholder)
- `StarterGui.LOOPlab.UI` (Folder, placeholder)

### MCP validation
- Verified Studio connectivity and full inspect → create → verify flow via MCP.
- Confirmed no script errors on placement.

### Out of scope (per PRD/AI_RULES)
- No services, economy, recommendation engine, monetization, mini-games, or UI
  built in this milestone.

### Known issues / risks
- None. Greenfield foundation.

### Next
- Milestone 1: (to be defined) — e.g. PlayerDataService + server-authoritative
  player data foundation.