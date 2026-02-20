# PresenceEvents Flow Notes

## RequestQuestUpdate

1. Called from `OnQuestWatchUpdate` (direct questID) or `OnQuestLogUpdate`/`OnUIInfoMessage` (blind, guessed ID).
2. Cancels any existing C_Timer for this questID (debounce).
3. Schedules `C_Timer.After(UPDATE_BUFFER_TIME, ...)` so we process the *final* state (fixes 55/100 → 71/100 flicker).

## ExecuteQuestUpdate

1. Timer fires; clear `bufferedUpdates[questID]`.
2. Fetch objectives via `C_QuestLog.GetQuestObjectives(questID)`.
3. Build serialized state string; compare with `lastQuestObjectivesCache[questID]`. Skip if unchanged.
4. Blind update suppression: if `isBlindUpdate` and `isNew` (no cache entry), skip (avoids popup on unrelated QUEST_LOG_UPDATE).
5. Update cache with new state.
6. Pick display text: first unfinished objective, or fallback to first objective, or "Objective updated".
7. Call `QueueOrPlay("QUEST_UPDATE", ...)` with `{ questID = questID }`.

## GetWorldQuestIDForObjectiveUpdate

1. Super-tracked quest (C_SuperTrack) if it's a WQ and not complete.
2. Else: `addon.ReadTrackedQuests()` → filter WORLD/CALLING, not complete, isNearby → first candidate.
3. Used for blind updates when we don't know which quest changed.
