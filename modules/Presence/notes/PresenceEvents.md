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

## Scenario Criteria Update (SCENARIO_UPDATE)

Delve and scenario objectives use C_ScenarioInfo (scenario criteria), not C_QuestLog. They cannot be tracked, so QUEST_WATCH_UPDATE never fires. This flow handles objective progress toasts for delves, party dungeons, and other scenarios.

### RequestScenarioCriteriaUpdate

1. Called from `OnScenarioCriteriaUpdate` when `wasInScenario` is true (i.e. after we've shown SCENARIO_START).
2. Cancels any existing C_Timer (debounce).
3. Schedules `C_Timer.After(SCENARIO_UPDATE_BUFFER_TIME, ExecuteScenarioCriteriaUpdate)`.

### ExecuteScenarioCriteriaUpdate

1. Timer fires; clear `scenarioCriteriaUpdateTimer`.
2. Guard: IsScenarioActive, showScenarioEvents, GetScenarioDisplayInfo.
3. Fetch main-step criteria via `GetMainStepCriteria()` (C_ScenarioInfo.GetCriteriaInfo / GetCriteriaInfoByStep).
4. Build state key; compare with `lastScenarioCriteriaCache`. Skip if unchanged.
5. Update cache with new state.
6. Pick display text: first unfinished criteria with text (plus X/Y if applicable), or "X/Y", or first text, or "Objective updated".
7. Resolve category from `GetScenarioDisplayInfo()` (DELVES | DUNGEON | SCENARIO).
8. Call `QueueOrPlay("SCENARIO_UPDATE", "SCENARIO UPDATE", text, { category = category })`.

### OnScenarioCompleted

Clears `lastScenarioCriteriaCache` and cancels `scenarioCriteriaUpdateTimer`.
