# Presence — User Overview

A high-level guide to when Presence shows notifications, what colours it uses, and how it handles multiple notifications at once.

---

## When Does Presence Show?

Presence displays cinematic-style notifications for these events:

### Zone & Exploration
- **Zone changes** — When you enter a new zone or major area (e.g. flying into a new region)
- **Subzone changes** — When you move into a subzone or district within a zone
- **Discovery** — Optional “Discovered” line when visiting a new area for the first time

### Character & Achievements
- **Level up** — When you gain a level
- **Achievements** — When you earn an achievement

### Boss & Encounter
- **Boss emotes** — When a raid or dungeon boss plays a scripted emote or announcement

### Quests
- **Quest accepted** — When you accept a new quest
- **World quest accepted** — When you accept a world quest
- **Quest progress** — When you make progress on a tracked quest objective (e.g. “7/10” updates)
- **Quest complete** — When you turn in a quest
- **World quest complete** — When you complete a world quest

### Scenarios, Delves & Dungeons
- **Scenario start** — When a scenario, delve, or dungeon begins
- **Scenario progress** — When you complete or advance objectives within a scenario, delve, or dungeon

---

## What Colours Does Presence Use?

Presence uses different colours to distinguish notification types. These can be customized in the addon’s colour options.

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
| **Quest progress**       | Varies by quest type | Matches the quest’s category            |
| **Scenario / Delve**     | Deep blue or teal    | Depends on scenario type                |

### Special Colours
- **Discovery line** — Soft green for “Discovered” when visiting a new area
- **Boss emote** — Red so it stands out during combat

All quest-related colours follow the addon’s quest-type colour scheme (Campaign, World, Legendary, Complete, etc.) and can be adjusted in options.

---

## Overwriting vs. Queuing

When several things happen at once, Presence either **interrupts** the current notification or **queues** it.

### When Presence Interrupts (Overwrites)

Presence will **immediately replace** the current notification if the new one is:

- **A different type** (e.g. zone change vs. quest progress), and  
- **The same or higher priority**

In other words, a more important or different kind of event can cut off what’s currently showing.

### When Presence Queues

Presence will **queue** the new notification if:

- It is the **same type** as what’s showing (e.g. another zone change), or  
- It has **lower priority** than the current notification

Notifications of the same type are queued so you see each one. Up to **5** items can wait in the queue. Duplicate notifications (same type and same text) are not added again.

### Priority Overview

Higher-priority notifications can interrupt lower-priority ones:

| Priority | Types |
|----------|-------|
| **Highest** | Level up, Boss emotes |
| **High**    | Achievements |
| **Medium**  | Quest complete, World quests, Zone changes, Scenario start |
| **Lower**   | Quest accept, World quest accept, Quest progress, Subzone change, Scenario progress |

### After a Notification Finishes

When the current notification finishes and exits, Presence picks the **highest-priority** item from the queue and shows it next. The rest stay queued until they are played or replaced.

---

## Summary

- **When:** Zone changes, level up, achievements, boss emotes, quest events, and scenario/delve progress.
- **Colours:** Each type has its own colour (quest types, red for boss emotes, green for discovery, etc.), customizable in options.
- **Overwriting:** Different, higher-priority events interrupt the current notification.
- **Queuing:** Same-type or lower-priority events are queued (up to 5); duplicates are skipped; highest-priority queued item plays next.
