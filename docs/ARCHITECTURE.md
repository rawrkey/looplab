# LOOPLAB — Architecture

> Source of truth for the technical structure. The Roblox Studio project (Place1)
> started as a clean SuperTemplate baseplate with **no existing scripts, folders,
> remotes, or UI**. This document defines the target architecture. Systems are
> introduced incrementally per milestone — **this document describes the target
> design, not everything built today.**

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
│           └── Services            (server-authoritative service scripts/mods)
│
├── ReplicatedStorage
│   └── LOOPlab
│       ├── Shared                  (shared modules used by server + client)
│       ├── Configuration           (centralized config, e.g. GameConfig)
│       └── Remotes                 (RemoteEvents/RemoteFunctions live here)
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       └── LOOPlab
│           └── Client              (client controllers / UI logic)
│
├── StarterGui
│   └── LOOPlab
│       └── UI                      (screen GUIs and UI components)
│
└── Workspace / Lighting / etc.     (scene content — hub built in later milestones)
```

Naming conventions:

- Root containers are named `LOOPlab` (project prefix) to avoid collisions and
  clearly mark ownership.
- Scripts: PascalCase. Modules: PascalCase. Folders: PascalCase.
- Remote names: `Remote`-born; single source of the remote wiring in
  `Shared/Remotes` module (RemoteGuardService target design).

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
PlayerDataService → compute authoritative results
    │
    ▼
[Server] broadcasts result to relevant clients (RemoteEvent)
    ▼
[Client controllers] update UI
    ▲
[AnalyticsService] records funnel/engagement events (both sides may emit)
```

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

- All remotes live under `ReplicatedStorage.LOOPlab.Remotes` as
  RemoteEvents/RemoteFunctions, referenced by a central definitions module.
- **RemoteGuardService** (target design) provides:
  - Server-side validation of every remote payload.
  - Rate limiting / throttling (per player, per remote).
  - Rejection logging (feeds analytics/anti-exploit).
- Convention: prefer RemoteFunction for request/response, RemoteEvent for
  one-way authoritative broadcasts and low-risk intents. Use the strictest
  mechanism that fits.

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

This is the target contract. Milestone 0 creates only the folders + GameConfig;
the registry contract is finalized when ActivityService is built.

---

## 18. Target Services (conceptual inventory)

| Service | Layer | Purpose |
|---|---|---|
| PlayerDataService | Server | Load/save/version player data |
| EconomyService | Server | XP/coins/currency authority |
| ActivityService | Server | Activity lifecycle orchestration |
| ActivityRegistry | Shared/Server | Activity metadata + registration |
| RecommendationService | Server | Next-activity suggestions |
| PartyService | Server | Party/friend grouping |
| RewardService | Server | Authoritative reward issuance |
| AnalyticsService | Server+Client | Telemetry/analytics events |
| MonetizationService | Server | Purchases (cosmetics) |
| ContentRegistry | Shared/Server | Content/cosmetic catalog + registration |
| RemoteGuardService | Server | Remote validation + rate limiting |

**Status:** These are target designs. Per project rules, systems are created
**only when a milestone needs them** — never "just because they appear in the
PRD." Milestone 0 creates only folders + GameConfig.

---

## 19. Milestone 0 State (what exists NOW)

- Local repo `Projects/looplab` with `docs/`.
- In-Studio scaffolding: `LOOPlab` container folders under ServerScriptService,
  ReplicatedStorage, StarterPlayerScripts, StarterGui.
- `ReplicatedStorage.LOOPlab.Configuration.GameConfig` ModuleScript
  (centralized config/version).
- **No services, no remotes, no economy, no gameplay code yet.**