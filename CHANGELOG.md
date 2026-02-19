# Changelog

All notable changes to Horizon Suite are documented here.

---

## [Unreleased]

### New Features

- **(Focus) Per-objective progress (e.g. 15/18) on individual objectives** — Objectives with multiple instances (e.g. "Pressure Valve fixed", "Cache and Release" valves) now display numeric progress when the API provides it, so you can see partial completion at a glance.

### Fixes

- **Focus Tracker — ADDON_ACTION_BLOCKED** — Fixed error when `HSFrame:SetSize()` (and other protected dimension calls) were invoked during combat when changing options. `ApplyDimensions` is now guarded by `InCombatLockdown()` and deferred until `PLAYER_REGEN_ENABLED`.

- **(Focus) Scenario and Delve objectives now show per-objective progress (e.g. 0/5 Workers rescued)** — Objectives from C_ScenarioInfo (Delves, scenarios, dungeons) now pass quantity/totalQuantity as numFulfilled/numRequired so the count displays correctly.

<!-- Changelog entries are generated from closed GitHub Issues at release time. -->

---

## [1.1.5] – 2026-02-19

### New Features

- **(Focus) Option to fade or hide completed quest objectives** — Completed objectives (e.g. 1/1) can be faded or hidden so remaining tasks are visible at a glance.

### Fixes

- **(Core)** Beta Release Action now runs correctly; release zipping and workflow updated.

- **(Focus)** Click to complete quest in old content (no turn-in NPC) now works; users no longer need to disable the addon to complete those quests.

---

## [1.1.4] – 2026-02-16

### New Features

- **(Focus) Quest text adapts to tracker height** — Full text shows or hides based on available space when the tracker is short.

- **(Vista)** Game reports addon action no longer blocked when opening the World Map.

- **Setting to hide or show the drag-to-resize handle** — Option for the bottom-right corner of the quest list.

### Fixes

- **(Focus)** Quest titles with apostrophes no longer show wrong capitalization (e.g. "Traitor'S Rest").

- **(Core)** Version number in settings window now matches the addon version.

- **(Presence)** Quest update bugs fixed: race conditions causing 0/X display, intermediate progress numbers, and suppressed completion toasts.

- **(Focus)** World quest zone labels corrected; in-zone redundancy and off-map missing labels fixed.

- **(Core)** Font dropdown is now scrollable so fonts below the fold can be selected.

- **(Focus)** SharedMedia compatibility added so addons and custom fonts can be used across the suite.

---

## [1.1.3] – 2026-02-15

### New Features

- **(Focus) In-zone world quests, weeklies and dailies** — Shown when in zone; right-click untracks and hides until zone change (not subzone). Option in Display → List to show a suffix for in-zone but not yet in log.

### Improvements

- **(Focus) Tracked WQs and in-log weeklies/dailies** — Now sort to the top of their section.

- **(Focus) Promotion animation** — Only the promoted quest fades out then fades in at the top; fixed blank space until next event.

- **(Focus) Right-click on world quests** — Untracks only (no abandon popup); Ctrl+right-click still abandons.

### Fixes

- **(Focus) Category reordering** — Drop target now matches cursor; auto-scroll direction when dragging near top or bottom corrected.

---

## [1.1.2] – 2026-02-15

### Fixes

- **(Focus)** Game sounds no longer muted or clipped when endeavor cache primes at login.

---

## [1.1.1] – 2026-02-14

### New Features

- **(Focus) Auto-track accepted quests** — Accepted quests are now automatically added to the Focus tracker. You can enable or disable this in Organization -> Behaviour.

### Improvements

- **(Focus) Endeavor tooltip rewards** — Endeavor hover tooltips now use the panel-style layout and include House XP with the chevron icon in the rewards section.

### Fixes

- **UI taint errors** — Fixed taint errors that could appear when opening Blizzard panels such as Character Frame and Game Menu.

- **(Focus) Shift+Right-click abandon** — Confirm abandon now works correctly when using Shift+Right-click on quests.

---

## [1.1.0] – 2026-02-14

### New Features

- **(Focus) Decor tracking** — Track Decor items in the Focus list. Shows item names; left-click opens the catalog; Shift+Left-click opens the map to the drop location.

- **(Focus) Endeavor tracking** — Track Endeavors in the Focus list. Names load on reload without opening the panel; left-click opens the housing dashboard.

- **(Focus) Achievement requirements display** — Option to only show missing requirements for tracked achievements; completed criteria are shown in green.

### Improvements

- **(Focus) Spacing slider** — Slider in Display → Spacing to adjust the gap below the objectives bar (0–24 px), preventing the first line from being cut off.

- **(Focus) Dim non-focused quests** — Display option to dim full quest details and section headers for non-focused quests.

### Fixes

- **(Focus)** World quests no longer remain in the tracker after changing zones (e.g. hearthing to another zone).

- **(Focus)** Confirm abandon quest now works when using Shift+Right-click.

---

## [1.0.6] – 2026-02-14

### Fixes

- **(Focus)** Quest text (objectives, timers) now updates during combat — Content-only refresh runs when ScheduleRefresh is requested in combat.
- **(Presence)** Quest progress and kills in combat now show Presence toasts — Removed combat lock in QueueOrPlay so progress and kills (e.g. Argent Tournament jousting) appear.

---

## [1.0.5] – 2026-02-14

### New Features

- **(Focus) Super-compact mode — options and collapse** — Super-minimal mode now has a thin bar with expand/collapse and a compact "O" options button. Objectives can be opened when "Start collapsed" is set.

---

## [1.0.4] – 2026-02-14

### Improvements

- **Focus — Quest-area world quests when option is off** — When "Show world quests" is disabled, the tracker still shows WQs when you physically enter their quest area (distance-based proximity using C_TaskQuest.GetQuestLocation, matching default Blizzard behavior). Zone-wide WQs remain hidden.

- **Presence — Colours and quest-type icon aligned with Focus** — Presence notifications now use the same colour palette and options as Focus. Quest Complete and Quest Accept colours are driven by quest type (campaign, world, default, etc.); Achievement uses Focus bronze; World Quest uses Focus purple; Quest Update uses Nearby blue; zone/subzone use default title and campaign gold subtitle. Boss emote uses a dedicated red in Config. When "Show quest type icons" is enabled in options, quest-related Presence toasts (accept, complete, world quest) show the same quest-type icon as the Focus tracker.

### Fixes

- **Focus Tracker — ADDON_ACTION_BLOCKED** — Fixed error when `HSFrame:Hide()` was called during combat. Protected Hide() calls are now guarded by InCombatLockdown() and deferred until PLAYER_REGEN_ENABLED.

---

## [1.0.3] – 2026-02-13

### New Features

- **Quest header count** — Option to show quest count as tracked/in-log (e.g. 4/19, default) or in-log/max-slots (e.g. 19/35). Uses `isHidden` for an accurate in-log count.

### Improvements

- **Focus — Granular spacing options** — Vertical gaps are now user-configurable via sliders in Display → Spacing: between quest entries (2–20 px), before and after category headers (0–24 px, 0–16 px), and between objectives (0–8 px). Compact mode applies a preset (4 px entries, 1 px objectives).

- **Presence — World Quest Accept** — World quest accepts now use a dedicated purple-style notification type (`WORLD_QUEST_ACCEPT`) instead of sharing the standard quest accept style.

---

## [1.0.2] – 2026-02-13

### New Features

- **Track specific world quests when WQs are off** — Watch-list and super-tracked world quests now appear in the tracker even when the general world quests option is disabled. You can turn off auto-added zone WQs while still seeing the ones you explicitly track.

### Improvements

- **Mythic+ design** — Improved M+ block layout and styling in the Focus tracker.

### Fixes

- **Focus Tracker — per-category collapse** — Section header collapse (clicking category headers like Campaign, World Quests) no longer delays or flickers. The collapse animation starts immediately and section headers stay visible during the animation.

- **Focus Tracker — main collapse** — Main tracker collapse behaviour refined: ensures the update loop runs when toggling collapse, and section headers display correctly when a single category is collapsed.

---

## [1.0.1] – 2026-02-13

### Fixes

- **Focus Tracker — completed achievements** — The tracker no longer clutters the list with achievements you’ve already finished. Completed achievements are hidden by default; you can turn on “Show completed achievements” in options if you want to see them.

- **Focus Tracker — collapse** — Collapsing the tracker now behaves correctly: the collapse animation starts right away, section headers stay visible while it animates, and a single category still shows its header when collapsed.

---

## [1.0.0] – 2026-02-13

### New Features

- **Modular architecture** — Horizon Suite is now a core addon with pluggable modules. The Focus (objective tracker) is the first module. A new **Modules** category in options lets you enable or disable each suite. Use `/horizon toggle` or Options → Modules → Enable Focus module to turn the tracker on or off. Additional suites will appear as modules in the same options panel. SavedVariables remain compatible; existing installs default to Focus enabled.

- **Presence module** — Cinematic zone text and notifications. Replaces default zone/subzone text, level-up, boss emotes, achievements, quest accept/complete/update, and world quest banners with styled notifications. Priority queueing, smooth entrance/exit animations, and "Discovered" lines for zone discoveries. Enable in Options → Modules → Enable Presence module. Test with `/horizon presence` (e.g. `/horizon presence zone`, `/horizon presence all`). Blizzard frames are fully restored when Presence is disabled. (Renamed from Vista; `/horizon vista` is now `/horizon presence`.)

### Improvements

- **Performance optimizations** — Reduced CPU usage by replacing per-frame OnUpdate with event-driven logic and timers: scenario heartbeat and map check now use C_Timer tickers; main tracker OnUpdate runs only when animating or lerping; Presence OnUpdate runs only during cinematics; scenario timer bars use a shared 1s tick instead of per-bar updates; options toggle OnUpdate runs only during its short animation.

- **Options panel UX overhaul** — Cinematic, modern, minimalistic redesign: softer colour palette with low-contrast borders and dividers; pill-shaped search input; taller sidebar tabs with hover states; minimal X close button; section cards with inset backgrounds; refined toggles, sliders, dropdowns, and colour swatches; subtle dividers between colour-matrix sections; consistent hover feedback on buttons and tabs.

- **Search bar redesign** — Custom-styled search input without Blizzard template: search icon (spyglass) on the left, integrated clear button (visible only when typing), subtle focus state with accent-colour border, and tighter visual connection to the results dropdown.

---

## [0.7.1] – 2026-02-13

### Improvements

- **Zone labels** — Refined how quest zone names are chosen so objectives show clearer, more accurate zone labels, especially when quests span parent/child maps.

- **Mythic+ integration** — Improved how Mythic+ objectives and blocks behave in the tracker and options, with clearer descriptions and more consistent behaviour.

- **Options usability** — Polished several option labels and descriptions (including Mythic+ and zone-related settings) to better explain what they do and how they interact.

- **Options panel overhaul** — Fixed search so clicking a result now switches to the correct category and scrolls to that setting. Settings are reorganized into eight categories (Layout, Visibility, Display, Features, Typography, Appearance, Colors, Organization) for easier discovery. Toggles use a rounded pill style; search results show category and section with the option name emphasised.

- **World quest map fallback removed** — World quests are now sourced only from live APIs (`GetTasksTable`, `C_QuestLog.GetQuestsOnMap`, `C_TaskQuest` map APIs, and waypoint fallback) without requiring the world map to be open. The previous map-open cache and heartbeat fallback have been removed.

---

## [0.7.0] – 2026-02-13

### Improvements

- **Version 0.7.0** — Release bump.

---

## [0.6.9] – 2026-02-13

### New Features

- **Nearby group toggle** — Toggle to show or hide the nearby group section, with key binding support. Key bindings can be set in the game’s Key Bindings → AddOns → Horizon Suite. Animation and behaviour for the nearby group section have been enhanced.

- **Dungeon support** — Quest tracking now supports Dungeon quests so dungeon objectives appear correctly in the tracker.

- **Delve support** — Delve quests are supported with updated event handling so Delve objectives are tracked and displayed.

### Improvements

- **Floating quest item button** — Styling, text case options, and UI layout improved. Button behaviour and layout (e.g. icon, label, progress) are more consistent and configurable.

- **Quest caching** — Quest ID retrieval and caching logic refactored for better reliability. Event handling and debugging around quest updates have been improved.

- **README** — Documentation revised for clarity and formatting.

---

## [0.6.6] – 2026-02-11

### New Features

- **Weekly quests** — New category for weekly (recurring) quests with its own section in the tracker. Weekly quests in your current zone are auto-added like world quests. Quest classification now uses a single source of truth for determining world quests.

- **Daily quests** — Daily quests are supported with their own section and labeling. Daily quests in your current zone are auto-added to the tracker. Quests that are available to accept but not yet accepted show an **"— Available"** label.

- **Focus sort mode** — In Options → Categories, you can choose how entries are ordered within each category: **Alphabetical**, **Quest Type**, **Zone**, or **Quest Level**. A new options section controls sorting within categories.

### Improvements

- **Quest caching** — Quest caching logic improved for your current zone and parent maps so quests display correctly without needing to open the map first.

- **Quest bar layout** — Left offset for quest bars adjusted for more consistent layout.

- **Database refactor** — All references updated from `HorizonSuiteDB` to `HorizonDB` for consistency. Options panel and quest tracking aligned to the new saved variable name; TOC and changelog updated accordingly.

---

## [0.6.5] – 2025-02-10

### New Features

- **Hide in combat** — New option in General (Combat section): when enabled, the tracker panel and floating quest item button are hidden while in combat. When combat ends, visibility is restored according to your existing settings (instance visibility, collapsed state, quest content). When **Animations** is enabled, the tracker and floating button fade out over ~0.2s on entering combat and fade in on leaving combat.

- **Focus category order** — The order of categories in the Focus list (Campaign, World Quests, Rares, etc.) can now be customised. In the options popout (Appearance), reorder categories via drag-and-drop; the new order is saved and used for section headers and section header colors. Use "Reset order" to restore the default order.

### Improvements

- **Settings panel** — The options/settings UI has been updated for clearer layout and easier navigation.

- **New settings** — A range of new options have been added across General, Appearance, and other sections so you can tailor the tracker and behaviour to your preference.

---

## [0.6] – 2025-02-09

### New Features

- **World quest tracking** — World quests in your current zone now appear in the tracker automatically, using both `C_QuestLog` and `C_TaskQuest` data. No need to track every WQ manually.

- **Cross-zone world quest tracking** — World quests you track via the map watch list stay in the tracker when you leave their zone. They are shown with an **[Off-map]** label and their zone name. Use **Shift+click** on a world quest entry to add it to your watch list so it appears on other maps.

- **World map cache** — Opening the world map caches quest data for the viewed map and your current zone. World quests appear more reliably and update when you change map or close the map.

- **Map-close sync** — Closing the world map after untracking world quests there updates the tracker immediately so untracked WQs are removed.

- **Per-category collapse** — Section headers (Campaign, World Quests, Rares, etc.) can be clicked to collapse or expand that category. Collapse state is saved per category. Collapsing uses a short staggered slide-out animation.

- **Combat-safe scrolling** — Mouse wheel scrolling on the tracker is disabled during combat to avoid taint.

### Improvements

- **Focus category reorder UX** — The category order list in options now uses live drag-and-drop: a ghost row follows the cursor, an insertion line shows the drop position, the list auto-scrolls when dragging near the edges, and Reset order updates the list immediately. All Focus groups (Campaign, Important, Quests, etc.) are always shown.

- **Nearby quest detection** — Parent and child maps are considered when finding “nearby” quests, so quests in subzones and parent zones are included.

- **Active task quests** — Quests from `C_TaskQuest.IsActive` (e.g. bonus objectives, invasion points) are shown in the tracker under World Quests.

- **Zone change behaviour** — World quest cache is cleared on major zone changes (`ZONE_CHANGED_NEW_AREA`) but kept when moving between subzones, reducing flicker when moving within a zone.

- **Delayed refresh** — An extra refresh runs 1.5s after login and after zone changes so late-loading quest data is picked up.

### Fixes

- **TOC** — Version set to 0.6. SavedVariables corrected to a single line: `HorizonDB`.

- **Debug overlay removed** — The development-only world quest cache indicator (bottom-left of screen when the map was open) has been removed from release builds.

- **World map hook polling** — Reduced from 30 retry timers to 5 when waiting for the world map to load; map show/hide hooks no longer reference the removed indicator.

### Technical

- World quest data flow uses `C_QuestLog.GetQuestsOnMap`, `C_TaskQuest.GetQuestsForPlayerByMapID`, and optional `WorldQuestDataProviderMixin.RefreshAllData` hook when available.
- Per-category collapse state is stored in `HorizonDB.collapsedCategories`.

---

## [0.5] and earlier

Initial release and earlier versions. See README.md for full feature list.
