# Presence — User Overview

A high-level guide to when Presence shows notifications, what colours it uses, and how it handles multiple notifications at once.

---

## When Does Presence Show?

Presence displays cinematic-style notifications for these events:

### Zone & Exploration
- **Zone changes** — When you enter a new zone or major area (e.g. flying into a new region)
- **Subzone changes** — When you move into a subzone or district within a zone
- **Discovery** — Optional "Discovered" line when visiting a new area for the first time

### Character & Achievements
- **Level up** — When you gain a level
- **Achievements** — When you earn an achievement

### Boss & Encounter
- **Boss emotes** — When a raid or dungeon boss plays a scripted emote or announcement

### Quests
- **Quest accepted** — When you accept a new quest
- **World quest accepted** — When you accept a world quest
- **Quest progress** — When you make progress on a tracked quest objective (e.g. "7/10" updates)
- **Quest complete** — When you turn in a quest
- **World quest complete** — When you complete a world quest

### Scenarios, Delves & Dungeons
- **Scenario start** — When a scenario, delve, or dungeon begins
- **Scenario progress** — When you complete or advance objectives within a scenario, delve, or dungeon

---

## What Colours Does Presence Use?

Presence uses different colours to distinguish notification types. These can be customized in the addon's colour options.

### Main Colours by Type

| Notification type        | Typical colour       | Notes                                   |
|--------------------------|----------------------|-----------------------------------------|
| **Level up**             | Green (Complete)     | Same as quest-complete style            |
| **Boss emotes**          | Red                  | Fixed red to stand out                  |
| **Achievements**         | Bronze/tan           | Trophy-like feel                        |
| **Quest complete**       | Green (Complete)     | Based on quest type when known          |
| **World quest**          | Purple               | Distinct from regular quests            |
| **Zone / subzone**       | Campaign gold or teal| Depends on context (delve, dungeon, etc.)|
| **Quest accepted**       | Varies by quest type | Campaign, Legendary, World, etc.         |
| **Quest progress**       | Varies by quest type | Matches the quest's category            |
| **Scenario / Delve**     | Deep blue or teal    | Depends on scenario type                |

### Special Colours
- **Discovery line** — Soft green for "Discovered" when visiting a new area
- **Boss emote** — Red so it stands out during combat

All quest-related colours follow the addon's quest-type colour scheme (Campaign, World, Legendary, Complete, etc.) and can be adjusted in options.

---

## Queuing

When several things happen at once, Presence **queues** new notifications instead of interrupting. Each notification plays in full; you see them in sequence.

### Queueing Rules

- When something is already showing, new notifications are added to the queue (up to **5**).
- Duplicate notifications (same type and same text) are not added again.
- When the current notification finishes, Presence picks the **highest-priority** item from the queue and shows it next.

### Subzone Exception

When zone text is showing and you move between **subzones within the same zone** (e.g. "Valdrakken" with "The Seat of Aspects" to "Artisan's Consortium"), the subtitle updates in place. No new notification is queued; the zone name stays as the heading and only the subzone line changes. This keeps movement within a zone smooth without stacking zone toasts.

### Priority Overview

When choosing which queued notification plays next, higher-priority items are preferred:

| Priority | Types |
|----------|-------|
| **Highest** | Level up, Boss emotes |
| **High**    | Achievements |
| **Medium**  | Quest complete, World quests, Zone changes, Scenario start |
| **Lower**   | Quest accept, World quest accept, Quest progress, Subzone change, Scenario progress |

---

## Summary

- **When:** Zone changes, level up, achievements, boss emotes, quest events, and scenario/delve progress.
- **Colours:** Each type has its own colour (quest types, red for boss emotes, green for discovery, etc.), customizable in options.
- **Queuing:** New notifications are queued when something is showing (up to 5); duplicates are skipped; highest-priority queued item plays next. Subzone-only changes update the subtitle in place.
