# Horizon Suite — Pipeline

*Tagged log: Bugs, Features, Modules, Ideas. Use tags + status + date. See "How to use" below.*

---

## How to use (for Cursor)

- **Entry format:** `tag` `status` `YYYY-MM-DD` [priority] module-tag Title. Optional detail or → plan link.
- **Tags:** `BUG`, `FEAT`, `MOD`, `IMPR`, `IDEA`, `DOC`
- **Status:** `OPEN`, `FIXED`, `CLOSED`
- **Priority** (optional, for OPEN): `P0` (major), `P1` (minor), `P2` (patch)
- **Module** (optional): `[Focus]` or `[Presence]` (in backticks so they read as tags), or omit for core/general
- **Log a bug:** Add under Open Items with `BUG` OPEN, date, optional [P2]. When fixed, add Changelog entry and move to Closed/Fixed.
- **Log a feature/plan:** Add under Open Items with `FEAT`/`MOD`/`IMPR` OPEN. When done, add Changelog and move to Closed/Fixed.
- **Log an idea:** Add under Open Items with `IDEA` OPEN.
- Use `YYYY-MM-DD` for dates. Keep entries one line when possible.

**Design language:**
- **Open Items / Closed-Fixed title:** User-facing only. Describe observable behaviour (bug) or capability (feature) in plain language. One sentence. No implementation detail, function names, or API names; put those in optional detail or a linked plan.
- **Changelog:** User-facing, non-technical. One sentence stating *what* was fixed or added for the user (no code, no API names). When closing an item, the changelog line echoes the Open Item title in user language.

---

## Changelog

- 2026-02-15 — Fixed reordering of organization categories: drop target now matches cursor; auto-scroll direction when dragging near top or bottom corrected.
- 2026-02-15 — `[Focus]` In-zone world quests, weeklies & dailies: shown when in zone; right-click untracks and hides until zone change (not subzone). Option to show `**` suffix for in-zone but not in log (Display → List).
- 2026-02-15 — `[Focus]` Tracked world quests and in-log weeklies/dailies sort to the top of their section.
- 2026-02-15 — `[Focus]` Promotion animation: only the promoted quest fades out then fades in at the top; fixed blank space until next event.
- 2026-02-15 — `[Focus]` Right-click on world quests untracks only (no abandon popup); Ctrl+right-click still abandons.

---

## Open Items

- `BUG` OPEN 2026-02-15 [P1] `[Focus]` "Click to complete quest" in old content (no turn-in NPC) does not work; user must disable addon to complete those quests.
- `BUG` OPEN 2026-02-15 [P2] `[Focus]` Quest items with cooldowns do not update/tick down when used in combat; stays stale even after leaving combat. Works fine outside combat.
- `BUG` OPEN 2026-02-15 [P2] `[Focus]` Hovering quest objectives does not show party member progress (default UI does). User unsure if bug or feature—parity with default tooltip.
- `FEAT` OPEN 2026-02-15 [P1] SharedMedia compatibility so addons/custom fonts can be used across the suite.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Setting to hide or show the options button.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Setting to hide or show the drag-to-resize handle (bottom-right corner of quest list).
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` "Show preview" button for all relevant features in options.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Separate "Hide in dungeons" setting from the M+ timer.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Separate text font, size, and color settings for the M+ module.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Add deaths to the M+ module (or confirm if already shown).
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Square minimap option.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Minimap sizing and free positioning.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Minimap border thickness and visibility control.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Replace MinimapButtonButton/Hiding bar with built-in opt-out list of addon buttons to show.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Zone text control: position, background color and visibility, font size, font.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Coordinates text: position and styling; optional format (decimal precision, X/Y prefixes).
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Time/clock text: same controls as coords; optional format options.
- `FEAT` OPEN 2026-02-15 [P1] `[Vista]` Default map button visibility, position, size, and custom icons.
- `BUG` OPEN 2026-02-15 [P2] `[Focus]` Quest list sometimes resizes to default/small height and shows only about one-and-a-half quests despite vertical size setting; rest requires scrolling.
- `BUG` OPEN 2026-02-15 [P2] `[Focus]` Game reports addon action blocked when opening the World Map.
- `BUG` OPEN 2026-02-15 [P2] Settings search: first open after reload, when clicking a search result the description is cut off until you scroll or switch tabs and back.
- `BUG` OPEN 2026-02-14 [P2] Font dropdown is not scrollable; fonts below the fold cannot be selected when the list is long.
- `FEAT` OPEN 2026-02-14 [P1] `[Focus]` Option to set different fonts for quest title, quest text, and zone text.
- `BUG` OPEN 2026-02-14 [P2] `[Focus]` Category prefix shows as a square instead of a dash (all fonts tested).
- `FEAT` OPEN 2026-02-14 [P1] `[Focus]` Option for a current-zone quest item button that can be keybound (ExtraQuestButton-style: use without clicking).
- `IMPR` OPEN 2026-02-14 [P1] `[Focus]` Add options to set header color and header height.
- `FEAT` OPEN 2026-02-15 [P1] `[Focus]` Option to blacklist wq/daily/whatever permanently; list of blacklisted quest IDs so users can add them back. Whitelist if tracked from the map.
- `FEAT` OPEN 2026-02-14 [P1] `[Focus]` Filter which kinds of world quests auto-add to the tracker (e.g. by type, reward, zone).
- `FEAT` OPEN 2026-02-14 [P1] `[Focus]` Tracker fades by default and appears on mouseover.
- `FEAT` OPEN 2026-02-14 [P1] Custom waypoints and farm routes similar to TomTom.
- `FEAT` OPEN 2026-02-14 [P1] `[Focus]` Add endeavours alongside achievements in the tracker.
- `IMPR` OPEN 2026-02-14 [P1] `[Focus]` Quest text clipped when tracker is short; adapt so full text shows or hides based on space.
- `FEAT` OPEN 2026-02-13 [P1] `[Presence]` Scenario start notification when entering Delve, scenario, or dungeon.
- `FEAT` OPEN 2026-02-13 [P1] `[Focus]` Add endeavours and recipes to the tracker, similar to achievements.
- `FEAT` OPEN 2026-02-13 [P1] `[Focus]` Show unaccepted quests in the current zone in the tracker.
- `BUG` OPEN 2026-02-13 [P2] `[Focus]` World quest zone labels wrong or missing (in-zone redundant; off-map sometimes missing).
- `BUG` OPEN 2026-02-13 [P2] `[Focus]` Warfront objectives not shown in the tracker.
- `BUG` OPEN 2026-02-13 [P2] `[Focus]` Pop-up quests not appearing in the log.
- `IMPR` OPEN 2026-02-23 [P2] `[Focus]` Options to desaturate or adjust alpha for dimmed non-focused quests (Display).
- `IMPR` OPEN 2026-02-13 [P1] Improve tracker performance and responsiveness.
- `IDEA` OPEN 2026-02-13 [P2] Integration with Auctionator/Auctioneer for search materials.
- `FEAT` OPEN 2026-02-13 [P1] Add Korean language support.

---

## Closed / Fixed

- `BUG` FIXED 2026-02-15 [P2] Rearranging order of categories: drop target matched cursor; auto-scroll direction when dragging near top/bottom corrected.
- `IMPR` CLOSED 2026-02-15 [P1] `[Focus]` Promotion animation fades only the promoted quest(s) in and out at the top; fixed blank space until next event.
- `BUG` FIXED 2026-02-15 [P2] `[Focus]` Game sounds were muted or clipped at login when endeavor cache was priming.
- `BUG` FIXED 2026-02-14 [P2] `[Focus]` Endeavor hover tooltip showed the wrong reward wording or icon and did not match the panel reward styling.
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Accepted quests auto-track in the focus tracker (quest log only; world quests unchanged). Option in Organization → Behaviour.
- `BUG` FIXED 2026-02-14 [P0] Taint errors (ADDON_ACTION_FORBIDDEN, secret number value) when opening Character Frame, Game Menu, and other Blizzard panels.
- `IMPR` CLOSED 2026-02-14 [P1] `[Focus]` Spacing slider for gap below objectives bar; prevents first line from being cut off.
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Added Decor tracking; left-click opens catalog, Shift+Left-click opens map to drop location.
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Added Endeavor tracking; names load on reload without opening the panel, left-click opens housing dashboard.
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Option to only display missing requirements for tracked achievements.
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Decor left-click opens catalog; Alt+Left-click preview; Shift+Left-click map.
- `IMPR` CLOSED 2026-02-14 [P1] `[Focus]` Dim full quest details and section headers for non-focused quests (Display option).
- `BUG` FIXED 2026-02-14 [P2] `[Focus]` World quest stayed in tracker after changing zones and could not be removed.
- `BUG` FIXED 2026-02-14 [P2] `[Focus]` Confirm abandon quest did nothing when using Shift+Right-click. Fixed: SetSelectedQuest → SetAbandonQuest → AbandonQuest (correct API sequence).
- `BUG` FIXED 2026-02-14 [P2] `[Focus]` Quest objectives and timers not updating while in combat.
- `BUG` FIXED 2026-02-14 [P2] `[Presence]` Quest progress and kills in combat not shown (e.g. Argent Tournament jousting).
- `FEAT` CLOSED 2026-02-14 [P1] `[Focus]` Add options button and show/collapse objectives in super compact mode.
- `BUG` FIXED 2026-02-13 [P2] `[Focus]` Tracker could error when hiding during combat.
- `IMPR` CLOSED 2026-02-13 `[Presence]` Colours and quest-type icon aligned with Focus; optional icon on toasts.
- `FEAT` CLOSED 2026-02-13 [P2] Quest header count: option for tracked/in-log (4/19) or in-log/max-slots (19/35).
- `IMPR` CLOSED 2026-02-13 `[Focus]` Granular vertical spacing sliders in Display → Spacing.
- `IMPR` CLOSED 2026-02-13 `[Presence]` Separate Presence type for World Quest accept.
- `FEAT` CLOSED 2026-02-13 [P1] `[Focus]` World quests appear when you enter the quest area (even when option is off).
- `FEAT` CLOSED 2026-02-13 [P1] Track specific world quests even when world quests are turned off.
- `BUG` FIXED 2026-02-13 [P2] `[Focus]` Tracker showed old completed achievements.
- `BUG` FIXED 2026-02-13 [P2] Collapse on Focus not working.
- `BUG` FIXED 2026-02-13 [P2] Per-category collapse (section headers) delayed or flickering.

---

