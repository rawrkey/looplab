# LOOPLAB — Product Requirements Document (PRD)

> This Markdown file is the **source of truth** for LOOPLAB development.
> Any PDF version is a human-readable snapshot/reference only and is NOT authoritative.

---

## 1. Vision

LOOPLAB is a fast-paced social Roblox experience built around short, replayable
mini-games and activities. It is designed to feel like a constantly changing
Roblox playground where players can instantly jump into a fun activity, play for
1–4 minutes, earn rewards, and keep moving.

The design draws inspiration from the engagement mechanics of short-form content
platforms (TikTok, Instagram Reels, YouTube Shorts), but **intentionally avoids
manipulative dark patterns**.

Goal: **FAST FUN + NOVELTY + SOCIAL PLAY + PERSONALIZATION + MASTERY + REPLAYABILITY.**

---

## 2. Game Concept

A hub-based playground of many small, replayable mini-games ("activities"). The
platform continuously recommends the next thing to play, keeping sessions short,
social, and varied. Players earn XP and currency, unlock cosmetics, customize
their avatar, and play with friends.

---

## 3. Target Audience

- **Primary:** Gen Alpha
- **Secondary:** Gen Z
- The game must be welcoming to new players while offering depth (mastery,
  cosmetics, progression) for returning players.

---

## 4. Core Gameplay Loop

```
JOIN
  ↓
GET A FUN ACTIVITY
  ↓
PLAY FOR ~1-4 MINUTES
  ↓
EARN XP / COINS / REWARDS
  ↓
CHOOSE WHAT TO DO NEXT
  ↓
PLAY ANOTHER ACTIVITY
  ↓
CUSTOMIZE / SOCIALIZE / PROGRESS
  ↓
REPEAT
```

Design constraints derived from the loop:

- Fun should happen within the **first 30–60 seconds** of joining.
- Activities should generally be **short** (1–4 minutes) and **replayable**.
- Players should **always have something obvious to do next**.
- New content must be **easy to add** without rewriting the game.

---

## 5. Example Activities

- **Chaos Run** — chaotic obstacle race.
- **Caption Clash** — submit/rank funny captions.
- **Build Blitz** — fast-paced building challenge.
- **Dodge Lab** — dodge incoming hazards.
- **Mystery Modifier** — activity with rotating random modifiers.
- **Friend Frenzy** — cooperative/social mini-game.
- **Tiny Tycoon** — compact tycoon-style loop.

These are examples to inform architecture. They are **not** all required for the
initial MVP (see MVP Scope).

---

## 6. Player Progression

Progression rewards continued play **without pay-to-win**. Progression direction
will primarily be **cosmetic and social** rather than raw power.

- Mastery: improving performance in activities.
- Accumulation: XP, coins, cosmetics, personalization.
- Milestones, daily challenges, and events drive return visits.

---

## 7. XP and Currency

- **XP** — tracks overall progress/mastery level.
- **One soft currency ("coins")** for the MVP (see Monetization).
- **Server-authoritative:** clients never control or trust XP/currency values.
- No pay-to-win purchases; cosmetics are the monetary focus.

---

## 8. Cosmetics

- Primary personalization layer and the **primary monetization direction**.
- MVP target: approximately **10–20 cosmetics** and a basic profile/loadout.
- Cosmetics should be server-validated before being granted/applied.

---

## 9. Social Systems

Social interaction is a core pillar. MVP social scope is intentionally light
(basic party/friend functionality). Larger social features are documented as
future direction, not built up front.

---

## 10. Party / Friend Gameplay

MVP scope: **basic party/friend functionality** — joining a party and playing
activities together. Full party management, invites, and cross-activity social
features are post-MVP.

---

## 11. Recommendation System

A system that suggests the "next activity" to keep players engaged and on a fun
loop. MVP: a **simple** recommendation system (e.g., variety + recent activity +
novelty weighting). A full model is future work and must be driven by real
analytics, not assumptions.

---

## 12. Onboarding

Players should reach fun within 30–60 seconds. Onboarding must be minimal,
mobile-friendly, and not block play. Tutorials are lightweight and activity-
specific, not a long linear intro.

---

## 13. Daily Challenges

A daily challenge provides a concrete short-term goal and rewards. This drives
return visits. MVP includes a basic daily challenge; richer live-ops is future.

---

## 14. Live Events

Temporary/rotating events add novelty and drive social play. Live events are
primarily **post-MVP/live-ops** direction, though the architecture should make
them possible to add without rewriting the game.

---

## 15. Monetization

- **Cosmetics are the primary monetization direction.**
- No pay-to-win, no power purchases, no manipulative dark patterns.
- Keep monetization honest and aligned with the "fast fun" philosophy.
- MonetizationService is a target architecture service; not built in Milestone 0.

---

## 16. Analytics

We will **optimize using actual analytics rather than assumptions.** Track key
funnel, engagement, and retention metrics. MVP: basic analytics. Analytics must
not collect private/PII data unnecessarily.

---

## 17. Retention Goals

- Fast time-to-fun (30–60s).
- Clear "what to do next" at all times.
- Rewards and progression that encourage returning.
- Daily challenges and social play to drive habit.

---

## 18. Performance Requirements

- Must run well on **mobile, PC, and controller**.
- Good frame rate on low-end mobile devices.
- Avoid unnecessary replication and heavy instances.
- Benchmark-driven optimization using analytics/perf tooling rather than guesses.

---

## 19. Security Requirements

- **Server authority** for all important game state (currency, XP, rewards,
  purchases, progression, competitive scores).
- **Never trust the client.**
- **Validate important actions on the server.**
- **RemoteEvents/Functions**: server-side validation + reasonable rate limiting.
- **No secrets, API keys, or credentials in scripts.**
- Basic anti-exploit protections are part of MVP.

---

## 20. MVP Scope

A polished, shippable first version containing:

- Polished central hub.
- **3 polished mini-games.**
- Basic party/friend functionality.
- XP.
- One soft currency.
- Basic player profile/loadout.
- Approximately **10–20 cosmetics**.
- Daily challenge.
- Simple activity recommendation system.
- Basic analytics.
- Server-authoritative economy.
- Mobile-friendly UI.
- Controller-friendly UI.
- Error/crash monitoring.
- Basic anti-exploit protections.

---

## 21. Explicitly Excluded Features

**Do NOT build these during the initial foundation (and keep them out of MVP):**

- Massive open world.
- Complex combat.
- Complex trading.
- Player-to-player item economy.
- UGC scripting.
- Voice-dependent gameplay.
- Procedurally generated worlds.
- Dozens of currencies.
- Huge inventory systems.
- Overly complex progression trees.

---

## 22. Launch Requirements

- Stable on mobile, PC, and controller.
- 3 polished mini-games + hub.
- Core loop works end-to-end (join → play → earn → choose next).
- Server-authoritative economy and data.
- Basic analytics + crash/error monitoring.
- Anti-exploit basics in place.
- Onboarding reaches fun fast.

---

## 23. Post-Launch / Live-Ops Direction

- Rotating activities and live events.
- Rich recommendation model driven by analytics.
- Expanded cosmetics and social systems.
- Seasonal/daily challenges, limited-time rewards.
- Scaling content via ContentRegistry so new mini-games plug in without
  rewriting the platform.

---

## 24. Definition of Done

A feature/milestone is **Done** when:

1. Gameplay/system behaves per the PRD/architecture.
2. Server authority and validation requirements are met (no client-trusted state).
3. Works on mobile, PC, and controller where applicable.
4. No regressions in existing systems.
5. Performance is acceptable and measured where relevant.
6. Documentation (PRD/ARCHITECTURE/CHANGELOG) is updated.
7. Tests/manual verification performed and recorded.
8. Known issues and risks are documented.
