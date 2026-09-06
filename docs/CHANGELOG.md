# LOOPLAB — Changelog

All notable changes to LOOPLAB are documented here. One entry per milestone.

Format: `## [Unreleased]` / `## [Milestone] — YYYY-MM-DD`

---

## [Unreleased]

### Milestone: Phase 6 — Runtime Verification Enablement (2026-09-06)

Recovered the repo → Studio → Play pipeline so the Phase 1–5 code can be runtime-tested. Actual tooling work (Rojo install, injection) — no source rewritten to work around the environment.

- **Pipeline enabled**: Repo → Rojo → Studio → Play now works. LOOPLAB built to `.rbxl`/`.rbxlx` via `rojo build` (49 `.luau`, clean), the full DataModel injected into Studio, and the real tree verified present (all modules, services, remotes, config).
- **Runtime boot verified**: 15 server services boot; 4 activities registered (`build_blitz`, `chaos_run`, `dodge_lab`, `sequence_sprint`); RemoteBuilder generated 16 RemoteFunctions + 16 RemoteEvents; client bootstrap/UI initialized (LOOPlab/LOOPlabFx/Freecam ScreenGuis).
- **Gameplay loop verified live (single-player)**: Queue → Match → Activity → Results flow ran end-to-end via the poll sync (0.45s).
- **Reward math verified live**: `dodge_lab` 1st place → `Xp=100` (= BaseXp 50 × PlacementMult[1] 2.0), `Level 2` (curve[2]=58 ≤ 100 < curve[3]=125), `Coins=300` (= BaseCoins 25 × 2.0 + LevelUpCoins 250). Every value matches `GameConfig` exactly.
- **Bug fixed**: `Hub.luau` used invalid Luau generic-for syntax (`for _, g in ({...}), (...) do`) disovered during runtime verification; corrected to a valid `ipairs` loop. Fresh `rojo build` verified the fix.

Verification status — kept honest:
- **Single-player runtime verification: PASS** (bootstrap, queue, match, activity, results, XP/level/coins).
- **Multi-client verification: BLOCKED by environment** — only one Studio client available; cannot verify survival elimination, podium, or cross-player leaderboard submission.
- **DataStore persistence verification: BLOCKED** — Studio disables data-store API access (`StudioAccessToApisNotAllowed`); PlayerData/leaderboard writes fail gracefully (in-memory fallback keeps gameplay runnable).

### Milestone: Phase 5 — Progression / Retention (2026-09-06)

Closed the progression/retention gaps in a server-authoritative way. Every reward/XP/level/mastery/badge/title value still flows through the existing services; nothing is client-supplied or faked.

- **Level curve (5.2)**: `GameConfig.Xp.LevelCurve` was 10 entries but `MaxLevel` was 50, so `GetLevelFromXp` could never return above level 10 — making the `level_25` badge impossible and capping everyone at level 10. Replaced with a 50-entry cumulative curve (index = level) matching `MaxLevel = 50`: level 10 ≈ 718 XP, level 25 ≈ 4333 XP, level 50 ≈ 18310 XP. All consumers (server `GetLevelFromXp`, client `xpNextFor`) read this single curve, so XP/level/level-up/UI now agree. Player-data-safe: players only ever move UP in level, never down.
- **Level-up reward + feedback (5.2/5.7)**: `Economy.AddXp` (the only XP writer) now detects the old→new level crossing, grants `Progression.LevelUpCoins` (250, previously dead config) per level gained, and pushes a `LevelUp` Fx. Client `HandleFxQueue` renders it via the existing `EffectsService.LevelUp`. Landed in the single choke point, so it applies for every XP source and is granted exactly once per level gained.
- **Mastery pacing (5.4)**: Removed the misapplied per-event `math.min(mxp, Xp.ScoreCap=100)` in `ProcessStandalone`/`ProcessSurvival`. It was flattening Win (140) / SurvivalWin (200) / SurvivalPodium (120) all the way down to 100, erasing the intended placement tiering and making rank-up over-grindy. Removed the now-dead `ScoreCap` and unused `Rewards.Mastery` config. Mastery rank colors remain driven by real server mastery data.
- **Badges/titles final-round semantics (5.5)**: `FinalRoundAppearances` only incremented on **wins** (survived all rounds), but the `final_round` badge ("Reach the final round 5 times") and `final_regular` title ("Final Round Regular") describe *reaching* the final round — which the non-winning finalists also do. It now increments when a player reaches the final round (survives rounds 1..N-1, i.e. `survivedRounds >= totalRounds - 1`), matching the field name and both descriptions. `survive_all` (Iron Mind, "Survive all four rounds in one match") is now granted on a Survival **win** (`Survival.Wins >= 1`) — it was previously stubbed to `false`.
- **Daily Challenge (5.6)**: Fixed the `win` objective that previously counted any participation (`score >= 1`) as a win — it now requires an actual win via new `isWin` argument threaded through `RecordProgress` (standalone: placement 1; survival: rank 1). Daily progress toasts only fire on a real increment. Client profile now shows the objective, live progress `(x/y)`, and the XP reward, plus a CLAIMED state.
- **Retention (5.7)**: Hub player pill now shows the next-level goal ("next: Lv N · X XP") with the XP bar; max level shows "max level reached".

### Milestone: Phase 4 — Premium UI/UX · Survival Presentation Flow (2026-09-06)

Improved the Survival presentation flow (MATCH FOUND → LINEUP → ROUND INTRO → GAMEPLAY → ELIMINATION → FINAL 3/2 → WINNER → RESULTS), closing the architectural gap that prevented clients from showing the match lineup. Data-driven, no faked data, reuses Theme/UIKit/ViewController/EffectsService/AudioService.

- **SurvivalMatchService.luau**: The per-match round order is now decided at match setup (before the lobby broadcast) and exposed to clients as `RoundOrder` in both the `LobbyUpdate` event and the `GetClientSync` Lobby payload (plus `TotalRounds`). This is the authoritative 4-game sequence (each game once, shuffled per match) that drives the lineup.
- **Queue.luau** (screen): Added a compact, data-driven **LINEUP** strip revealing the upcoming 4-game sequence (ROUND 1..4 pills with round number, game name, and per-game accent). `SetLineup(roundOrder, title)` rebuilds from the authoritative order each call; gracefully handles empty/1/short/full lists and missing name/icon (falls back to the activity id). No hardcoded player count or identities. Enlarged panel (0.5→0.62) and rebalanced layout so it stays responsive on PC, mobile portrait/landscape, and controller, while LEAVE QUEUE and the countdown/bar stay immediately accessible.
- **QueueController.luau**: Forwards `RoundOrder` to the Queue screen and now threads `Mode`/`ActivityId` through to the Results screen (so the mode chip correctly reads SURVIVAL).
- **Bootstrap.client.luau**: Survival Lobby poll path forwards `RoundOrder` to the controller.
- **EffectsService.luau**: `RoundBanner` now renders round progress as `ROUND n / N` for multi-round matches (Survival's 4 rounds), making escalation explicit; single-round standalone falls back to `ROUND n`.
- Reviewed/passed without change: Match HUD (activity accent, round n/4, timer, escalating Survival intensity ladder), Elimination (self-out flash + spectator vs. others-out toast), Final 3 / Final 2 escalation banners + SFX, and Winner (local "YOU" gold vs. opponent name) — all already coherent with the PRD flow.

Note: LIVE player-count refresh during an already-active Survival lobby is not re-polled on every tick (pre-existing Bootstrap behavior fires the Lobby update only on the Lobby transition). Kept as-is (no fabricated data); a later pass can re-poll state live if desired.

### Phase 4 — Premium UI/UX · Secondary Screens + Accessibility (2026-09-06)

Completed the remaining Phase 4 screens, preserving the shared Theme/UIKit component language across all of them. No new UI framework, no architecture rewrite.

- **Profile.luau**: The identity-card signature accents (top edge + avatar-ring stroke) now follow the player's actual mastery color instead of a hardcoded gold, tying the identity frame to real progression.
- **Leaderboards.luau**: Added honest name resolution — entries render the display name when the player is currently connected (or when the entry carries a Name/DisplayName), falling back to "Player #id" otherwise. No fabricated identities; the leaderboard store ships userId only, so only real, present players are named.
- **Cosmetics.luau** (reviewed/passed): Already consistent with the shared component language — titles tap-to-equip, owned-vs-locked badge collection, and no fake data.
- **Hub.luau** (reviewed/passed): Already a strong command center whose per-activity accents (`chaos_run→Primary`, `dodge_lab→Danger`, `build_blitz→Warning`, `sequence_sprint→Secondary`, `survival→Theme.Accent("survival")`) exactly match the Queue/Match-HUD/Results flow — the visual language is unified across the Survival flow and the Hub.
- **Settings.luau** (accessibility fix): Reduced Motion was previously never applied to the runtime — `UIKit.ReducedMotion` was never set, and `Settings:Apply` was never invoked. Now:
  - Toggling Reduced Motion applies to `UIKit.ReducedMotion` immediately.
  - `Settings:Apply` sets `UIKit.ReducedMotion` (for boot/load paths).
  - Persisted prefs are now honored at boot: `ProgressionController.ApplyProfile` calls `Settings:Apply(profile.Settings)` because `ProfileFetch` already returns the saved `Settings`.
  - Full loop now works: boot apply → toggle (immediate) → `SettingsSet` persist → next session restore.

### Milestone: Phase 3 — Game Feel (2026-09-06)

Introduced a lightweight, server-authoritative gameplay-feedback layer that reuses the game's existing poll→Fx→client pipeline (the same channel as badge/title/level-up notifications). No new remotes, no architecture rewrite.

- **ActivityService.luau**: The `OnUpdate` handler now detects a `Fx = { Kind, Data, TargetUserId? }` field on activity payloads and routes it into the per-player `PollService` feedback queue. Supports per-player targeting (`TargetUserId`) so only the affected player hears/sees the feedback; otherwise broadcasts. `PollService` is required lazily at runtime to avoid a circular-load.
- **New `FeedbackController.luau`** (client): Maps activity-Fx kinds to `AudioService` SFX plus a subtle on-screen telegraph. Per-kind throttle + coalescing prevent burst feedback (e.g. rapid block placement) from flooding the queue or spamming audio. Honors `UIKit.ReducedMotion` for the visual portion only — audio always plays.
- **ProgressionController.luau**: `HandleFxQueue` now delegates the activity-Fx kinds (`checkpoint`, `finish`, `hit`, `place`, `correct`, `wrong`, `roundclear`) to `FeedbackController`, alongside the existing progression kinds.
- **ChaosRun.luau**: Emits `checkpoint` Fx on a successful checkpoint and `finish` Fx on completing the track.
- **DodgeLab.luau**: Emits `hit` Fx (with hit count) whenever a player is struck by a hazard.
- **BuildBlitz.luau**: Emits `place` Fx per player block placement, server-side throttled (≥0.12s) so rapid placement doesn't flood the queue.
- **SequenceSprint.luau**: Emits `wrong` Fx on a mistake and `roundclear` Fx on completing a full sequence.
- **default.project.json**: Mapped new `FeedbackController` (49 total `.luau` files, all mapped, no orphans).

Note: This milestone fixes a real delivery gap — the in-activity `Message`/phase payloads broadcast via the `ActivityUpdate` remote had no client listener, so per-event feedback was previously dropped. Feedback now rides the working poll path (≤0.45s latency, acceptable for passive/success/failure feedback).

### Milestone: Foundation + Survival Core (2026-09-06)

**Phase 1 — Foundation fixes**
- **default.project.json**: Added 7 missing Rojo mappings — `ProgressionService`, `PollService` (services), `LabEnvironment` (server script), `Cosmetics` screen, and `Theme`/`AudioService`/`EffectsService` (client components). All 48 `.luau` files are now mapped. Previously the client would crash on `require` of unmapped `Theme`/`AudioService`/`EffectsService`/`Cosmetics`, and the server would warn missing `ProgressionService`/`PollService`.
- **ChaosRun.luau**: Fixed checkpoint system (3 bugs):
  - `CPIndex` now set inside the `Start()` creation loop (was run in `Create` when `Checkpoints` was empty → attribute never set).
  - `touchBind` was defined but never called — now invoked per player in `Start()`.
  - Touch/respawn connections now stored in `TouchConns` and disconnected in `Cleanup()` (was leaking). Added `CharacterAdded` rebinding for respawn.
- **Hub.luau**: Wired live progression into the top-right player pill — Level (`Lv N`), Coins (`◉ N`), Mastery chip (colored rank pill), and an XP progress bar. `SetProgression`, `SetMastery`, and `SetRecords` (incl. Survival best-wins on the hero card) are now implemented from authoritative server data.

**Phase 2 — Survival Core**
- **GameConfig.luau**: Added `Survival.DifficultyProgression` (`Normal → Hard → Hard → Extreme`) and `DifficultyMultipliers` (Normal/Hard/Extreme tables for time, hazard rate, hazard max, show time, input window, block cap).
- **SurvivalMatchService.luau**:
  - Round order is now randomized per match (`shuffledRoundOrder`); each activity appears exactly once per match.
  - Per-round difficulty is resolved from `DifficultyProgression` and forwarded into `CreateSession` → activities.
  - Fixed final-round elimination: `keep=1` now applies after the safety clamp, so the final round correctly reduces to a single winner (previously the clamp could prevent elimination when `keep >= #aliveList`).
- **DodgeLab.luau**: Difficulty scales hazard spawn rate, max concurrent hazards, and round duration.
- **SequenceSprint.luau**: Difficulty scales sequence show time and input window (faster/easier to fail on higher tiers).
- **BuildBlitz.luau**: Difficulty scales the block placement cap.
- **ChaosRun.luau**: Difficulty scales round duration (tighter timer on higher tiers).
- **Plus**: Each activity now captures `deps.Difficulty` in `newSession`.
- **ProgressionService.luau**: Fixed `survive_all` badge (Iron Mind) — now correctly detects surviving the whole match via `FinalRoundAppearances >= 1` (only the winner survives all rounds). Was hardcoded `return false`.
- **MatchController.luau**: Forwards survival `Difficulty` into the HUD sub-label so escalation is visible.

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
