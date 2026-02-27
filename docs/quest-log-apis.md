# Quest log APIs — header count ("in log")

Notes on WoW `C_QuestLog` APIs used to count **accepted** quests in the player's quest log (for the Focus header "in log" value). Run `/h focus headercountdebug` to compare methods in-game.

## Goal

Count only quests the player has **accepted** (in the Blizzard quest log), excluding:
- Headers
- World quests (optional, we exclude for "in log")
- Entries that appear in the log UI but are not accepted (e.g. "Order of Embers" / available campaign quests)

## Relevant APIs

| API | Purpose |
|-----|--------|
| `C_QuestLog.GetNumQuestLogEntries()` | Returns `(numShownEntries, numQuests)`. First = loop bound (includes headers). Second = documented "actual quests" but in practice can include non-accepted (e.g. 55 when accepted is lower). |
| `C_QuestLog.GetInfo(questLogIndex)` | Returns QuestInfo (questID, isHeader, isHidden, questClassification, …). Includes all log entries (accepted + available). No "isAccepted" field. |
| `C_QuestLog.GetQuestIDForLogIndex(questLogIndex)` | Returns questID or nil. Nil for headers; non-nil for quest rows. Same pool as GetInfo — does not filter by accepted. |
| `C_QuestLog.IsOnQuest(questID)` | Returns whether the player has **accepted** this quest. Use this to filter out "available" / campaign entries that appear in the log but are not accepted. |
| `C_QuestLog.IsWorldQuest(questID)` | Use to exclude world quests from the count if desired. |
| `C_QuestLog.GetLogIndexForQuestID(questID)` | Returns log index if quest is in the log. Used for "is this in the log?" checks; not used for iterating. |
| `C_QuestLog.GetNumQuestWatches()` + `GetQuestIDForQuestWatchIndex(i)` | Returns only **tracked** quest IDs, not all accepted. Cannot use for "total in log". |

## Current approach (production)

1. Loop `i = 1, numEntries` where `numEntries = select(1, GetNumQuestLogEntries())`.
2. For each `i`: `info = GetInfo(i)`.
3. Count when: `info` and `not info.isHeader` and **`not info.isHidden`** and `info.questID` and `not IsWorldQuest(questID)` and **`IsOnQuest(questID)`**.

Production uses **GetInfo + not isHidden + IsOnQuest + not WQ**. The **isHidden** filter restricts to quests visible in the Blizzard quest log; **IsOnQuest** excludes available-but-not-accepted entries (e.g. "Order of Embers").

## Alternative approaches (compared in debug)

- **GetQuestIDForLogIndex(i)** — Same loop, get questID via GetQuestIDForLogIndex(i) instead of GetInfo(i).questID; then apply IsOnQuest + not IsWorldQuest. Should match GetInfo+IsOnQuest count.
- **Second return value (numQuests)** — Use `select(2, GetNumQuestLogEntries())`. In retail this can over-count (e.g. 55) because it includes non-accepted entries.
- **GetInfo + not isHidden** — Used in production. `isHidden` = "not visible in the player's quest log". Excludes campaign/available entries that inflate the count.

## References

- [C_QuestLog.GetInfo](https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetInfo) — QuestInfo fields (isHeader, isHidden, questClassification).
- [C_QuestLog.GetNumQuestLogEntries](https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetNumQuestLogEntries) — Returns (numShownEntries, numQuests).
- [C_QuestLog.GetQuestIDForLogIndex](https://warcraft.wiki.gg/wiki/API_C_QuestLog.GetQuestIDForLogIndex) — "Only returns a questID for actual quests, not headers".
- Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua (IsOnQuest, IsWorldQuest, etc.).
