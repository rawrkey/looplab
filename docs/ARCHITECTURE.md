# LOOPLAB — Architecture

> Source of truth for the technical structure. The Roblox Studio project (Place1)
> started as a clean SuperTemplate baseplate with **no existing scripts, folders,
> remotes, or UI**. The full MVP architecture described below is **built and
> playtested** as of v2. Studio is the live truth; the repo (`src/`) mirrors it
> 1:1 via Rojo.

---

## 1. Principles

- **Modularity:** every major feature is a module with clear ownership.
- **Server authority:** the server owns all important state (currency, XP,
  rewards, purchases, progression, competitive scores).
- **Minimal dependencies:** no unnecessary packages or cross-module coupling.
- **Centralized config:** no scattered magic values (RULE 8 of AI_RULES).
- **Easy content addition:** new mini-games plug in through registries without
  rewriting the platform.
- **Never casually rewrite** working systems (RULE 5 of AI_RULES).

---

## 2. Container Layout

```
ROBLOX PROJECT (Place: Place1 / 95206881)
│
├── ServerScriptService
│   └── LOOPlab
│       └── Server
│           ├── Services            (server-authoritative service modules)
│           ├── Activities          (mini-game modules registered into ActivityRegistry)
│           └── Bootstrap           (Script — starts services in dependency order)
│
├── ReplicatedStorage
│   └── LOOPlab
│       ├── Shared                  (Types, ActivityContract, ActivityRegistry,
│       │                            RemoteDefinitions, RemoteBuilder)
│       ├── Configuration           (GameConfig — centralized tunables)
│       └── Remotes                 (Runtime-created by RemoteBuilder; single flat
│                                    folder of RemoteEvents/RemoteFunctions)
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       └── LOOPlab
│           └── Client
│               ├── Bootstrap       (LocalScript — builds UI + runs poll loop)
│               ├── Components      (Screens/*, ViewController, UIKit, Theme,
│               │                    EffectsService, AudioService)
│               └── Controllers     (Hub, Queue, Match, Spectator, Progression,
│                                    Leaderboard)
│
└── Workspace / Lighting / etc.     (scene content)
```

Notes:

- **UI is built at runtime**, not stored in StarterGui. `Client/Bootstrap`
  creates one `ScreenGui` (background panel + 8 screens) inside `PlayerGui`.
- **Remotes are created at runtime** by `RemoteBuilder` from
  `RemoteDefinitions` (idempotent, single flat `Remotes` folder).
- Naming: root containers are `LOOPlab`; scripts/modules/folders PascalCase;
  remote names defined only in `RemoteDefinitions`. Component source uses the
  Rojo mapping `src/<Service>/<LOOPlab path>/...`.

---

## 3. Server / Client Responsibilities

### Server (ServerScriptService/LOOPlab/Server)
- Authoritative game state: currency, XP, rewards, purchases, progression,
  competitive scores, activity outcomes.
- Data persistence (DataStore) with save-data versioning.
- Validates and rate-limits all Remote communication.
- Owns activity lifecycle authority (start/end/score validation).
- Broadcasts authoritative results to clients.

### Shared (ReplicatedStorage/LOOPlab/Shared)
- Pure logic/constants that both sides use (types, config read, utility funcs).
- Remote definitions (names/signatures) — the contract both sides code against.
- **No client-owned mutable game state lives here.**

### Client (StarterPlayer/StarterPlayerScripts/LOOPlab/Client + StarterGui)
- Presentation, input, UI, animation, feedback.
- Sends *intent* to the server (e.g. "enter activity X"), never authoritative
  results.
- Optimistic UI only where the server is the final authority.

---

## 4. Data Flow (high-level)

```
[Client] sends intent (RemoteFunction/RemoteEvent, fire-and-forget or await)
    │   (rate-limited + validated by RemoteGuardService on server)
    ▼
[Server services] validate → execute (EconomyService etc.) → persist via
PlayerDataService → compute authoritative results, buffer into PollService
    │
    ▼
[Client] polls PollActivity RemoteFunction every ~0.45s (v2 sync)
    ▼
[Client controllers] update UI
    ▲
[AnalyticsService] records funnel/engagement events (server + client)
```

### 4.1 Sync strategy (v2): poll + event

Studio play (no networking job) breaks `RemoteEvent/BindableEvent` signal
delivery client-side. `PollService` is therefore the **sync backbone**:

- Every client runs a poll loop from `Client/Bootstrap` calling
  `Remotes.Functions.PollActivity` (RemoteFunction) on an interval that stays
  under `RemoteGuardService`'s per-remote throttle.
- `PollActivity` returns a single payload:
  `{ Activity = <current snapshot or nil>, Economy = {Coins, Xp, Level},
  Toasts = {{message}} }`.
- `Activity` has a `Mode`: `"Queue" | "Standalone" | "Survival"` (with
  `Phase`: `Lobby | Countdown | Running | Aborted`) | `"Results"`.
- The server **also fires** RemoteEvents for production use; the poll path is
  fallback-equivalent and what's exercised in playtests.
- Controllers (Queue/Match/Progression) translate payloads into UI updates;
  broadcast-style events are consumed when present, poll updates otherwise.
- Rate is tuned in `GameConfig` (see `Remotes`/`Poll`); exceeding the guard's
  throttle returns errors, so the client never spams faster than configured.

---

## 5. Player Data

- Owned by **PlayerDataService** (server-side).
- Single player-data schema with a **schema version** field.
- Saved via DataStore (`OrderedDataStore`/`DataStore` as appropriate).
- **Schema migration/versioning required** before any schema change
  (RULE 14 of AI_RULES).
- Never trust client-supplied data; data loads on `PlayerAdded`-equivalent,
  tracked as authoritative source of truth while the player is in the server.

Target data shape (conceptual):

```
PlayerData {
  SchemaVersion: number,
  XP: number,
  Coins: number,
  LastSeen: number,
  DailyChallenge: { Date: string, State: ... },
  Loadout: { EquippedCosmetics: [...] },
  OwnedCosmetics: [...],
  Stats: { ... activity stats ... },
  ...
}
```

---

## 6. Activity Lifecycle

Conceptual states per player/activity session:

```
Pending → Countdown → Active → Ending → Rewards → Done (back to hub/next)
```

- **ActivityService** orchestrates lifecycle on the server.
- **ActivityRegistry** registers activities: each mini-game declares metadata
  (id, name, min/max players, duration, reward rules, prerequisite config).
- Server is authoritative over start/end and score → reward outcomes.
- Clients render the active state and send intents; they never decide scores.

---

## 7. Rewards

- **RewardService** computes and issues rewards on the **server** after validated
  activity results.
- Rewards: XP, coins, cosmetics (server-granted into owned inventory), event
  tokens (future).
- Reward tables/rates live in centralized config, not scattered around scripts.

---

## 8. Remote Communication

- `RemoteBuilder` (Shared) creates every remote at runtime, idempotently, from
  `RemoteDefinitions` (Shared) into a single flat
  `ReplicatedStorage.LOOPlab.Remotes` folder.
- `RemoteGuardService` (Server) wraps every remote:
  - Server-side validation of every payload.
  - Rate limiting / throttling (per player, per remote) — e.g. a 15-call window
    per 5s.
  - Rejection logging (feeds analytics / anti-exploit).
- Convention: RemoteFunction for request/response (QueueJoin, QueueLeave,
  PollActivity, ProfileFetch, DailyState, DailyClaim, LeaderboardFetch,
  SettingsSet), RemoteEvent for authoritative broadcasts (ActivityStart,
  ActivityUpdate, RoundEnd, MatchResult, Economy). The strictest mechanism wins.
- The poll loop rate is the only client traffic that must survive throttling;
  it is configured in `GameConfig.Remotes.Poll`.Interval.

---

## 9. Recommendation System

- **RecommendationService** (server) suggests the next activity.
- MVP: simple, deterministic-ish logic (recently played, variety, novelty,
  player stats, party state).
- Post-MVP: model driven by real analytics (RULE 12 of AI_RULES — optimize with
  data, not assumptions).

---

## 10. Economy

- **EconomyService** (server) is the only writer of XP/coins/currency.
- Exposed through validated, rate-limited remotes.
- Client never holds or mutates authoritative balances.
- Configuration (currency names, rates, caps) centralized in GameConfig.

---

## 11. Monetization

- **MonetizationService** (server) handles purchases (cosmetics).
- Cosmetics are the primary monetization direction; **no pay-to-win**.
- Server-authoritative grants; client purchases go through validated flows.
- Not built yet — target design.

---

## 12. Analytics

- **AnalyticsService** records engagement/funnel/retention events.
- Basic analytics in MVP; expansion driven by data needs.
- Respect privacy; no unnecessary PII.
- RemoteGuard rejection logs and crash/error monitoring feed into analytics.

---

## 13. Security

- Never trust the client (RULE 9).
- Validate important actions on the server (RULE 10).
- Remote validation + rate limiting (RULE 11).
- No secrets/credentials in scripts (RULE 13).
- Server-authoritative competitive scores.

---

## 14. Error Handling

- Services catch and log errors with context (player, activity, remote).
- Player data load/save failures handled gracefully (retry, backoff, quarantine).
- Client handles missing/offline server responses gracefully.
- Crash/error monitoring (MVP: "basic error/crash monitoring").

---

## 15. Performance

- Minimize replication (only replicate what clients need).
- Prefer parts/effects that are cheap on mobile.
- Profile with real tooling (perf profiler + analytics) before optimizing.
- Batched/coalesced UI updates; avoid per-frame work where avoidable.

---

## 16. Save-Data Versioning

- Every PlayerData schema has a `SchemaVersion`.
- Migration path: load → detect old version → migrate → save latest.
- Never silently drop old fields without a documented migration.
- Document schema changes in ARCHITECTURE + CHANGELOG (RULE 15).

---

## 17. How to Add a New Mini-Game (target flow)

1. Add activity metadata to **ActivityRegistry** (id/name/duration/player
   limits/rewards/config).
2. Add reward rules to centralized config.
3. Implement server-side logic in the activity's server module (lifecycle,
   score validation, result emission).
4. Implement client presentation/controller for the activity.
5. Register via the registry. The platform (hub, rewards, recommendation)
   picks it up automatically.
6. No rewriting of platform systems required.

This is the contract v2. New activities register their module under
`Server/Activities` and declare metadata in `ActivityRegistry`; the platform
(hub, queue, survival rounds, rewards) picks them up automatically.

---

## 18. Services (built inventory)

| Service | Layer | Purpose |
|---|---|---|
| PlayerDataService | Server | Load/save/version player data (SchemaVersion) |
| EconomyService | Server | XP/coins/level authority + grant |
| ActivityService | Server | Activity lifecycle orchestration |
| QueueService | Server | Queue/lobby management → match launch |
| SurvivalMatchService | Server | Survival round orchestration + eliminations |
| DailyChallengeService | Server | Daily XP-bonus challenge |
| PollService | Server | Per-player activity snapshot for the v2 poll sync |
| RewardService | Server | Authoritative reward issuance |
| LeaderboardService | Server | Scoreboard entries per board |
| CosmeticService | Server | Cosmetic catalog / owned cosmetics |
| MonetizationService | Server | Purchases (cosmetics; shell) |
| SpectatorService | Server | Survivor/eliminated tracking for spectating |
| AnalyticsService | Server+Client | Telemetry/analytics events |
| RemoteGuardService | Server | Remote validation + rate limiting |
| ActivityRegistry | Shared | Activity metadata + registration (all 4 games) |
| RemoteBuilder / RemoteDefinitions | Shared | Runtime remote creation from the single contract |
| GameConfig | Configuration | All tunables (rewards, timings, economy, remotes) |
| ViewController + UIKit + Theme | Client | Runtime-built UI: 8 screens, styling, brand |
| Bootstraps (Server/Client) | Both | Dependency-ordered startup + poll loop |

**Not built (target only):** RecommendationService, PartyService,
ContentRegistry. Built systems remain server-authoritative; UI is presentation
only.

---

## 19. Current State (v2)

- **Repo** `Projects/looplab` with `src/` mirroring Studio 1:1 (Rojo) and
  `docs/`.
- **Server** (`ServerScriptService.LOOPlab.Server`): `Services/` (13 modules +
  RemoteGuardService), `Activities/` (ChaosRun, DodgeLab, BuildBlitz,
  SequenceSprint), `Bootstrap` Script.
- **Shared** (`ReplicatedStorage.LOOPlab`): `Shared/` (Types, ActivityContract,
  ActivityRegistry, RemoteDefinitions, RemoteBuilder), `Configuration/`
  (GameConfig), runtime `Remotes/`.
- **Client** (`StarterPlayerScripts.LOOPlab.Client`): `Bootstrap` LocalScript,
  `Components/` (8 Screens + ViewController, UIKit, Theme, EffectsService,
  AudioService), `Controllers/` (Hub, Queue, Match, Spectator, Progression,
  Leaderboard). UI is built into a single runtime ScreenGui under PlayerGui.
- **Sync:** poll-based fallback via PollService (v2), RemoteEvents fire for
  production; playtested end-to-end (standalone + solo survival → Results,
  coins/XP awarded, victory overlay).
- **Remaining:** Datastore-backed leaderboards/dailies confirmed, cosmetics
  catalog + purchase flow, in-Studio multiplayer verification.