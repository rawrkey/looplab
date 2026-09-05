# LOOPLAB - Product Requirements Document

**Version 2.0 - Updated Game Structure**
**Date:** September 5, 2026

> This Markdown file is the development source of truth. The PDF is a human-readable snapshot.

## 1. Executive Summary

LOOPLAB is a competitive social Roblox experience built around four short, replayable mini-games and a fifth mode that combines all four into an escalating survival tournament.
The game serves two complementary player types: competitive players who want to survive the full LOOPLAB tournament and climb leaderboards, and casual players who simply want to practice, chill, and improve at an individual mini-game.
The four mini-games are the building blocks of the product. The fifth mode - LOOPLAB Survival - is the flagship experience and the main reason the individual games exist.

## 2. Product Vision

Make a Roblox game that is immediately understandable, fast to enter, exciting to watch, satisfying to replay, and easy to expand with new games and difficulty variations.
Core promise: enter a match, survive four different challenges, outlast everyone else, and become the LAST ONE STANDING.
Design pillars: fast fun, escalating tension, skill, variety, social play, replayability, mastery, and clean progression.

## 3. Target Audience

Primary audience: Gen Alpha.
Secondary audience: Gen Z.
Player motivations include competition, mastery, funny moments, social play, visible status, quick sessions, and the desire to improve.
Both mobile-first and PC/controller players should receive a complete experience.

## 4. Game Structure

LOOPLAB has exactly five top-level playable menu options at MVP launch:
1. Mini-game A - standalone mode
2. Mini-game B - standalone mode
3. Mini-game C - standalone mode
4. Mini-game D - standalone mode
5. LOOPLAB Survival - a tournament that rotates through all four mini-games.
The four individual games are placeholders until final game concepts are selected. The architecture must allow them to be swapped or expanded without rewriting the platform.

## 5. The Four Individual Mini-Games

Each individual mini-game must be fun on its own and have its own skill curve, scoring rules, leaderboard, and replay value.
Examples that may be used during prototyping include Chaos Run, Dodge Lab, Build Blitz, Caption Clash, or other games approved later.
Individual mode goals:
Players can queue directly into the game.
Players can replay the same game as often as they like.
Players can improve their personal score or performance.
Players can view a leaderboard for that specific game.
Players still earn normal progression rewards.
The final four games are not locked by this document; they should be selected based on fun, technical feasibility, variety, and replayability.

## 6. Flagship Mode - LOOPLAB Survival

LOOPLAB Survival is the central competitive mode.
Target lobby size: 10 players.
A match consists of four rounds. Each round uses one of the four mini-games.
Default round order should rotate between matches so the same game is not always first or last.
Players are eliminated between rounds based on validated game performance.
The remaining players advance until one player wins the entire sequence.
Suggested elimination pacing for a 10-player lobby:
Round 1: 10 -> 8 players
Round 2: 8 -> 5 players
Round 3: 5 -> 3 players
Round 4: 3 -> 1 winner
The exact elimination thresholds should be configurable and can be tuned after playtesting.

## 7. Difficulty Escalation

The Survival mode should become harder as the tournament progresses.
Difficulty can increase through faster hazards, fewer safe areas, tighter time limits, stronger modifiers, more complex objectives, or other game-specific escalation.
Escalation should feel fair and readable. Difficulty should increase the tension without becoming random nonsense.
Every mini-game should support a normal standalone difficulty and one or more higher-pressure Survival variants.

## 8. Match Flow

1. Player enters Survival queue.
2. Lobby fills or match countdown begins.
3. Match intro shows the four games in the upcoming sequence.
4. Round begins.
5. Players compete.
6. Server validates results.
7. Rewards and standings are calculated.
8. Eliminated players enter spectator mode.
9. Surviving players advance.
10. Next round starts.
11. Final player wins.
12. Winner celebration and results screen.
13. Players return to the hub with clear options to replay, select an individual game, customize, or join another Survival match.

## 9. Spectator Mode

Players eliminated from Survival should not be immediately kicked to the lobby.
Eliminated players should be able to spectate remaining players, especially during the final rounds.
Spectators may use lightweight reactions or emotes, provided these do not interfere with gameplay or moderation requirements.
Spectating exists to preserve the social story of the match: Round 1 -> Round 2 -> Final 3 -> Final 2 -> Winner.

## 10. Leaderboards

LOOPLAB must have two leaderboard categories.
Individual game leaderboards track performance in each mini-game. Depending on the game, this may be highest score, fastest completion, longest survival, highest streak, or another clear metric.
Survival leaderboards track prestigious long-term achievements such as total Survival wins, podium finishes, or a configurable Survival rating.
Leaderboards should be easy to understand and should not require players to spend Robux to compete.

## 11. Player Experience and Onboarding

The player should understand the core premise within the first minute.
First-session flow:
Spawn -> see the five menu options -> receive a clear explanation of Survival -> play or practice one game -> earn a reward -> return to the hub.
Onboarding must be minimal. The game should demonstrate rather than force a long tutorial.
Players should always have a clear next action after a match or elimination.

## 12. Core Progression

Players earn XP for playing and progressing through games.
One soft currency, Coins, is planned for MVP.
Cosmetics, titles, badges, and profile identity are the main long-term progression layers.
Winning Survival should feel prestigious but should not unlock unfair gameplay advantages.
Individual mini-game mastery can provide personal goals, records, and cosmetic/status rewards.

## 13. Social Systems

Social play is a core pillar.
MVP social scope includes shared lobbies, party/friend play where feasible, visible match status, emotes/reactions, and spectator moments.
Private-server support can be added as a later monetization/social feature.
The design should create moments worth sharing without requiring voice chat.

## 14. Recommendation and Discovery Inside the Game

The in-game recommendation layer should help players choose what to do next without replacing the five-mode structure.
After completing a game, the hub can recommend one or more activities based on recent history, variety, preferences, party state, and event status.
Survival remains a primary option rather than being hidden behind recommendations.
The system should avoid recommending the exact same game repeatedly unless the player clearly prefers it.

## 15. Daily and Live Content

Daily challenges provide short-term goals such as completing a specific game, surviving a certain round, or achieving a target score.
Live events can temporarily modify game rules, reward cosmetics, or highlight particular mini-games.
New mini-games, modifiers, maps, cosmetics, and events should plug into the system through registries rather than require large rewrites.

## 16. Monetization

Core gameplay must remain free-to-play.
Primary monetization direction: cosmetics, profile customization, game passes, developer products, and private servers where appropriate.
No pay-to-win mechanics.
Monetization should not gate the basic four games or Survival mode behind payment.
Paid features must not undermine the competitive integrity of leaderboards.

## 17. Analytics and Success Metrics

Product decisions should be driven by observed player behavior rather than assumptions.
Track at minimum:
First-session completion/bounce
Time to first playable round
Mini-game completion
Survival participation
Survival completion
Elimination round distribution
Replay rate
Play days per player
Co-play days
Individual leaderboard engagement
Survival leaderboard engagement
Day 1 / Day 7 / Day 28 retention
Cosmetic conversion
Robux spend
Crash/error rate
Mobile performance

## 18. Security and Fairness

The server is authoritative for currency, XP, rewards, purchases, match state, eliminations, final scores, and leaderboard results.
Never trust the client to declare a score, completion, survival state, or reward.
RemoteEvents and RemoteFunctions must validate payloads and use sensible rate limits.
Purchase receipts and reward grants must be validated server-side.
Competitive scores should be checked for impossible values and invalid state transitions.

## 19. Technical Architecture Requirements

Target architecture remains modular and uses clear ownership.
Conceptual services include PlayerDataService, EconomyService, ActivityService, ActivityRegistry, RecommendationService, PartyService, RewardService, AnalyticsService, MonetizationService, ContentRegistry, and RemoteGuardService.
These are target services, not a requirement to create everything immediately.
ActivityRegistry is particularly important: each mini-game should expose metadata such as ID, name, player limits, duration, supported difficulty, scoring method, rewards, and Survival compatibility.
ActivityService should orchestrate both standalone games and the four-round Survival sequence.
The Survival system should consume registered activities rather than hard-code each game's logic into the tournament controller.

## 20. Data Model Requirements

Player data should include a schema version.
Target fields include XP, Coins, owned cosmetics, equipped cosmetics, individual game statistics, Survival statistics, daily challenge state, and recent activity history.
Potential Survival statistics include wins, final-round appearances, rounds survived, and best placement.
Save-data changes require migration planning and documentation.

## 21. MVP Scope

Polished central hub with five clear mode choices.
Four polished mini-games.
LOOPLAB Survival mode using all four mini-games.
Target 10-player lobby.
Four-round escalating structure.
Elimination system.
Spectator mode.
Winner celebration/results.
Individual game leaderboards.
Survival leaderboard.
XP and one soft currency.
Basic profile/loadout.
10-20 cosmetics.
Daily challenge.
Basic analytics.
Server-authoritative rewards and scores.
Mobile-friendly UI and controller-friendly UI.
Basic anti-exploit and error monitoring.

## 22. Explicitly Out of Scope for MVP

Massive open world.
Complex combat system.
Complex trading or player-to-player economy.
UGC scripting.
Voice-dependent mechanics.
Procedurally generated worlds.
Dozens of currencies.
Huge inventories.
Overly complex skill trees.
Dozens of mini-games at launch.
The architecture should support growth, but MVP should focus on four excellent mini-games rather than quantity.

## 23. Content Expansion Strategy

After MVP, the fastest growth path is to add more content without changing the core platform.
Potential expansion:
New mini-games can be added to the four-game pool.
Game-specific modifiers can increase replayability.
Survival can rotate its four-game selection from a larger catalog.
Limited-time events can temporarily alter the sequence or difficulty.
New leaderboards can be introduced for seasons or events.
This keeps the core identity stable while expanding the amount of content available.

## 24. Definition of Done

A feature is done when it works in the real multiplayer game, has server-authoritative behavior where required, does not regress existing systems, works on supported input platforms, has acceptable performance, is testable, and is documented.
For Survival-specific features, done also means the feature behaves correctly across all four rounds, handles elimination/spectating, preserves the correct winner, and cannot be trivially manipulated by the client.

## 25. Milestone Roadmap

Milestone 0 - Foundation: documentation, folder architecture, configuration, Git workflow.
Milestone 1 - Hub + navigation: five mode menu, basic hub, mode selection.
Milestone 2 - Mini-game framework: ActivityRegistry + ActivityService + first game.
Milestone 3 - Mini-games 2-4: complete the four-game pool.
Milestone 4 - Survival Alpha: 10-player flow, four rounds, elimination, winner.
Milestone 5 - Spectator + results: spectator mode, winner screen, match history.
Milestone 6 - Progression: XP, Coins, player data, rewards.
Milestone 7 - Leaderboards: individual and Survival leaderboards.
Milestone 8 - Cosmetics + profile: loadout and first cosmetic catalog.
Milestone 9 - Analytics + balancing: instrument the loop and tune difficulty/eliminations.
Milestone 10 - Polish + launch prep: mobile/controller UX, performance, anti-exploit, onboarding, thumbnails, testing.

## 26. AI-Assisted Development Contract

Future AI coding sessions must read PRD.md, ARCHITECTURE.md, AI_RULES.md, and CHANGELOG.md before editing.
AI must inspect the current project before making changes.
AI must work milestone by milestone and avoid building unrequested systems.
AI must preserve existing APIs and data compatibility unless a change is explicitly approved.
AI should first propose a plan for substantial changes, then implement the smallest safe increment.
After every milestone, AI should report changed files/objects, tests, issues, risks, and the next milestone.