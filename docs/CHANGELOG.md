# LOOPLAB — Changelog

All notable changes to LOOPLAB are documented here. One entry per milestone.

Format: `## [Unreleased]` / `## [Milestone] — YYYY-MM-DD`

---

## [Unreleased]

### Bug Fixes (QA + Hardening pass)
- **PollService.luau**: Fixed broken `pcall(require, script.Parent.DailyChallengeService)` — now properly requires `DailyChallengeService` at the top of the file (matches the pattern used by other services) and pcall-wraps the GetState call. Resolves daily-state never being included in poll payload.
- **SurvivalMatchService.luau**: Added nil-safety in `ApplyGroupElimination` for `row.Player` (player disconnected during a round). Added nil-safety in `FinishMatch` to skip disconnected players when granting rewards, saving data, and firing client events. Resolves hard-crash when a player leaves mid-round.
- **QueueService.luau**: Added `p.Parent` check in `startStandalone` and `startSurvival` to filter out disconnected players before starting a match. Added invalid-player guard in `Enqueue`. Resolves a queued disconnect from leaking into a session.
- **ActivityService.luau**: Added nil-safety for `p` in the `_lastResults` write loop inside `EndSession`. Resolves crash when a player disconnects between session start and end.
- **Spectator.luau**: Fixed `SetCycle` to use a local guard + fallback assignment so empty Cycle data does not wipe the existing cycle list. Resolves empty cycle after a spectator-rebroadcast.
- **Profile.luau**: Replaced hardcoded `id=0` avatar URL with `Players:GetUserThumbnailAsync` against the local player. Resolves placeholder silhouette instead of real avatar.
- **ActivityRegistry.luau**: Kept `GetDef` as a backwards-compatible alias of `Get` and added a comment. Removes redundant function while preserving any external call sites.
- **HubController.luau**: Added `Theme` import so per-activity accent is forwarded into the queue panel for a unified activity-color identity.
- **MatchController.luau**: Extended `ActivityUpdate` payload to forward `Mode`, `Round`, `TotalRounds`, `ActivityId`, and `SubLabel` to the HUD. Survival intensity ladder now updates live on the match bar.
- **MatchHud.luau**: Added mode-aware survival intensity bar, low-time warning color, round counter, sub-label slot, and timer chip layout. Removed dead `SetIntensity(level, max)` that took a 2nd positional arg while callers were passing nothing.

### UI / UX Redesign Pass
- **Theme.luau**: Refined palette (Background / Panel / PanelAlt / Stroke ramp), introduced `Lighten` companion to `Darken`, added `Stroke` constants, `Chip`/`Card`/`SectionLabel`/`StatBox`/`ProgressBar` helpers, added `IsTouch` runtime helper, and pulled in the new `Display` font token.
- **UIKit.luau**: Added themed `Card`, `Stroke`, `Gradient`, `Chip`, `SectionLabel`, `StatBox`, `ProgressBar`, `IconButton`, `SlideUpIn` and `Display` primitives. Reduced-motion gates are honored globally. Buttons are now `Lighten`-aware and pop on press without hard-coded hex.
- **EffectsService.luau**: Reinforced countdown typography with `Display` font, added reveal cards, refined banner and victory animations, and reduced transparency.
- **Hub.luau**: New command-center layout. Brand row + level / mastery / coins strip + XP bar + Survival flagship card (gradient + flagship chip) + 2×2 activity grid + nav bar. Per-activity accent drives both card and queue color.
- **Queue.luau**: Brand-aligned queue panel with display countdown (`X / Y`), gradient fill bar, large `LEAVE QUEUE` button, accent-driven top stripe.
- **MatchHud.luau**: New top bar with activity title + sub-label, round counter, large timer with low-time warning, phase label, and a survival-only intensity bar that lerps through `Success → Accent` as rounds progress.
- **Results.luau**: Podium layout with `1ST/2ND/3RD` chips for the top three, larger reward bar, animated row entrance, mode chip, and cleaner card chrome.
- **Spectator.luau**: New compact card with avatar ring, target name, counter chip `n/m`, and prev/next cycle buttons.
- **Profile.luau**: Identity header with avatar ring + level + title + mastery chip, stat grid using `StatBox` primitive, records strip, badge wall, scrollable title row, polished daily claim bar.
- **Cosmetics.luau**: Streamlined title showcase + full badge wall rendering all badges from `GameConfig.Badges` with owned/locked states.
- **Leaderboards.luau**: Tab bar with active accent highlight, podium row treatment (`1ST/2ND/3RD`), empty-state message, and per-board color theming.
- **Settings.luau**: Three-card toggle layout (Music / SFX / Reduced Motion) with descriptive subtitles, gradient Save button, close icon.

### Known Limitations
- **Multiplayer verification**: PASS WITH LIMITATION — only single-player Studio testing performed. True Survival elimination (10→8→5→3→1) and multi-client leaderboard submission need a live server.
- **DataStore persistence**: PASS WITH LIMITATION — Studio `StudioAccessToApisNotAllowed` for `DataStoreService:GetAsync`. Implementation is correct (the `PlayerDataService.Load` failure path falls back to default data, then `Save` retries on the regular save interval).
- **UI live verification**: Some Studio viewports cache the prior UI between play sessions; the live game was confirmed to load all services and the client, but exact pixel layout verification on every screen requires a clean Studio re-sync.

---

## [Milestone 0] — Project Foundation — 2026-09-05

### Local repository
- Created `Projects/looplab` as the LOOPLAB project root.
- Initialized Git repository (`main` + `develop` branches).
- Added `docs/` Markdown documentation as the source of truth.

### Documentation
- `docs/PRD.md` — product requirements (vision, concept, audience, loop, activities, progression, XP/currency, cosmetics, social, parties, recommendation, onboarding, daily challenges, live events, monetization, analytics, retention, performance, security, MVP scope, excluded features, launch requirements, live-ops, definition of done).
- `docs/ARCHITECTURE.md` — target modular architecture (server/shared/client split, services, data flow, player data, activity lifecycle, rewards, remotes, recommendation, economy, monetization, analytics, security, error handling, performance, save-data versioning, how to add mini-games).
- `docs/AI_RULES.md` — the 20 mandatory AI development rules + milestone workflow + git conventions.
- `docs/CHANGELOG.md` — this file.

### Roblox Studio scaffolding (non-destructive)
The place was a clean SuperTemplate baseplate (no scripts/folders/remotes/UI). Created scaffolding only — no gameplay code:
- `ServerScriptService.LOOPlab.Server.Services` (Folder, placeholder)
- `ReplicatedStorage.LOOPlab` (Folder) → `Shared`, `Configuration`, `Remotes`
- `ReplicatedStorage.LOOPlab.Configuration.GameConfig` (ModuleScript) — centralized configuration module (version constant + placeholder config)
- `StarterPlayer.StarterPlayerScripts.LOOPlab.Client` (Folder, placeholder)
- `StarterGui.LOOPlab.UI` (Folder, placeholder)

### MCP validation
- Verified Studio connectivity and full inspect → create → verify flow via MCP.
- Confirmed no script errors on placement.

### Out of scope (per PRD/AI_RULES)
- No services, economy, recommendation engine, monetization, mini-games, or UI built in this milestone.

---

## [PRD v2.0 Adoption] — 2026-09-05

### Product direction change
- Old concept (open "playground" of many mini-games) replaced by **v2.0**: exactly **4 standalone mini-games + 1 flagship LOOPLAB Survival mode**.
- Survival = 10-player lobby, 4 rounds (one per game), escalating difficulty, elimination (default 10→8→5→3→1, configurable), spectator mode, last-one-standing.
- Added: per-game leaderboards + prestigious Survival leaderboard.
- `docs/PRD.md` synced to v2.0 (26 sections) — new authoritative source of truth.
- `docs/ARCHITECTURE.md` updated to reflect Survival orchestration, ActivityRegistry contract, spectator, queue/lobby, leaderboard, and updated milestone roadmap.
- Gave a full planning blueprint (24 sections) covering all systems; approved.
