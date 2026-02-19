# 🌌 Horizon Suite

[![Release](https://img.shields.io/github/v/release/Crystilac93/Horizon-Suite?display_name=release)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Release Date](https://img.shields.io/github/release-date-pre/Crystilac93/Horizon-Suite)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Beta](https://img.shields.io/github/release-date-pre/Crystilac93/Horizon-Suite?label=beta&color=orange)](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta)

[![Discord](https://img.shields.io/discord/1471477531805749412?label=Discord&labelColor=%237289da)](https://discord.gg/MndCSYQ2ra) [![Patreon](https://img.shields.io/badge/build-donate-orange?label=patreon)](https://www.patreon.com/c/HorizonSuite) [![Ko-fi](https://img.shields.io/badge/build-tip-purple?label=Ko-fi)](https://ko-fi.com/horizonsuite) 

**Horizon Suite** is a core addon with pluggable modules: **Focus** (objective tracker) and **Presence** (zone text & notifications). Designed for the Midnight era—clean, cinematic, player-in-control. It replaces static, cluttered lists with a fluid interface that grants you total agency over your goals. Additional suites will appear as modules in the same options panel.

<p align="center">
  <img width="400" alt="Horizon Suite Preview" src="https://github.com/user-attachments/assets/72072df2-7ba3-4205-a984-df561eaf3ed4" />
</p>

---

## 🧠 Intelligent Logic
The systems driving your efficiency.

* **Spatial Awareness** – Automatically filters quests by zone and floats nearby objectives to the top. Tracks sub-zones and micro-dungeons instantly without requiring a map refresh. The Nearby (Current Zone) grouping can be toggled on or off via keybind, `/horizon nearby`, or Display → List.
* **Dynamic Scanning** – Surfaces active Scenarios, Delves, and World Events in dedicated, high-priority sections. Includes support for cinematic progress bars, timers, and difficulty tiers. In Delves, the list shows only delve objectives and scenario steps, not quests from the surrounding zone.
* **Rare Boss Tracker** – Scans for nearby vignettes, allowing you to super-track rares with a single click and optional audio alerts.
* **Achievement Tracking** – Tracked achievements appear in a dedicated Achievements section. Left-click opens the achievement panel; right-click removes it from tracking. Toggle visibility in Features → Achievements. Completed achievements are hidden by default; enable "Show completed achievements" to include them. Use "Show achievement icons" to toggle achievement icons independently of quest type icons. Enable "Only show missing requirements" to display only criteria you haven't completed for each achievement, reducing clutter while the progress count (e.g. 9/10) still reflects full completion.
* **Endeavor Tracking** – Tracked Endeavors (Player Housing) appear in a dedicated Endeavors section. Left-click opens the housing dashboard; right-click removes it from tracking. Toggle visibility in Features → Endeavors. Completed Endeavors are hidden by default; enable "Show completed endeavors" to include them. Endeavors use C_Endeavors / C_PlayerHousing when available (Midnight).
* **Decor Tracking** – Tracked housing decor appears in a dedicated Decor section. Left-click opens the decor catalog to that item; Alt+Left-click opens a quick preview; Shift+Left-click opens the map to where it drops. Right-click removes it from tracking. Toggle visibility in Features → Decor. Use "Show decor icons" to toggle decor icons independently of quest type icons.
* **Auto-Track on Accept** – When you accept a normal quest (quest log only; campaign, important, dailies, etc.), it is automatically added to the tracker so it appears immediately. World quests are unchanged—they still appear when in zone and can be manually tracked if desired. Toggle in **Options → Organization → Behaviour**.
* **Live Sync** – World Quests, Dailies, and Weeklies update dynamically so you never miss a pickup. World quests and weeklies/dailies that are in zone but not in your quest log show a ` **` suffix after the title (toggle in Display → List: "Show '**' in-zone suffix"). Dungeon objectives are supported and appear in the tracker. The world quest list is re-evaluated when you move between zones. World quest visibility can be toggled in Features → Show world quests. When off, tracked (Shift+Click), super-tracked, and WQs you physically enter the quest area of still appear; zone-wide WQs remain hidden.
* **Secure Quest Items** – High-performance quest item buttons built on secure templates, ensuring they work flawlessly mid-fight without UI errors.
* **ATT Integration** – Full native support for **All The Things**, displaying collection data directly within your objectives.
* **Presence Notifications** – Cinematic zone text, subzone changes, and "Discovered" lines. Level-up, boss emotes, achievements, quest accept/complete/update, world quest accept, world quest complete, and scenario start banners appear as styled notifications with priority queueing and smooth entrance/exit animations. When you enter a Delve, scenario, or party dungeon, a toast shows the scenario name and first step. Presence uses the same colour scheme and options as Focus (including the Color Matrix); quest-type colours apply to Quest Complete and Quest Accept, and when "Show quest type icons" is enabled, quest-related toasts show the same quest-type icon as the tracker. Scenario start respects "Show scenario events" in Features. Off by default (still being refined); enable in Modules → Enable Presence module if desired.

---

## 🎨 Visuals & UI Design
An aesthetic that complements the modern game client.

* **Visual Hierarchy** – High-fidelity icons for Campaign, Legendary, and World Quests. Use "Dim non-focused quests" (Display) to dim title, zone, objectives, and section headers that are not focused.
* **Completed Objectives** – For multi-objective quests, use "Completed objectives" (Display → List) to show all, fade completed objectives (e.g. 1/1), or hide them so you can quickly see what remains.
* **Per-Objective Progress** – Objectives with multiple instances display their numeric progress (e.g. 15/18) directly in the list when the API provides it, so you can see partial progress at a glance.
* **Turn-In Guidance** – Quests "Ready for Turn-in" receive a unique, high-contrast visual highlight and priority positioning, giving you a clear signal to head back to the hub. Auto-complete quests (no NPC turn-in needed) show "(click to complete)"—left-click to finish them directly.
* **The Color Matrix** – Define your own aesthetic with per-category colour customization (Title, Objective, Zone, Section) via `/horizon options`. Each category group is collapsible with a reset button. Current Zone and Ready to Turn in colours are grouped under Grouping Overrides.
* **Localization** – The options panel and settings support multiple languages. Korean (koKR) is bundled; the addon falls back to English for missing translations. Additional locales can be added by creating `options/{locale}.lua` files (e.g. `options/deDE.lua`).
* **Typography Suite** – Total control over fonts, sizes, outlines, and text shadows for Headers, Titles, and Objectives. Optional text case: set the main OBJECTIVES header, section headers and quest titles to Lower Case, Upper Case, or Proper (title case).
* **Fluid Motion** – Smooth entry/exit animations, a subtle "pulse" on objective completion, and adaptive layouts that support "Grow Upward" anchoring.
* **Granular Spacing** – Adjust vertical gaps via sliders in Display → Spacing: between quest entries, before and after category headers, between objectives, and the gap below the objectives bar. Compact mode applies a preset (4 px entries, 1 px objectives); sliders let you fine-tune each gap independently.

---

## ⚔️ Performance & Utility
Built for the heat of gameplay.

* **Hide in Combat** – Maintain total focus during encounters. The tracker can be set to automatically vanish the moment you enter combat, clearing your screen for boss mechanics and reappearing instantly once the fight is over.
* **Mythic+ Integration** – Cinematic banner for dungeon name, keystone level, timer, completion %, and affixes. Hover the banner to see detailed modifier descriptions.
* **Instance Visibility** – Granular control over where the tracker appears. Choose to show or hide the interface specifically for Dungeons, Raids, Battlegrounds, or Arenas. Filter by zone to hide quests outside your current zone entirely.
* **Compact & Minimal Modes** – Optimize your screen real estate with adjustable spacing, "Super-Minimal" headers (hides the OBJECTIVES header and quest count for a pure text list), and backdrop opacity controls. Super-minimal mode keeps a thin bar with expand/collapse and options (shown on hover) so you can open options and expand the list when starting collapsed. Header count format (Display → Header): choose **Tracked / in log** (e.g. 4/19, default) or **In log / max slots** (e.g. 19/35); tracked excludes world/live-in-zone quests.

---

## 🕹️ Controls & Interaction

### Slash Commands
| Command | Action |
|:---|:---|
| `/horizon options` | Launch the customization suite. Use the search bar to find and jump to individual settings. |
| `/horizon toggle` | Enable or disable the Focus (objective tracker) module. |
| `/horizon collapse` | Toggle the entire tracker or specific categories. |
| `/horizon nearby` | Toggle the Nearby (Current Zone) grouping on or off; when off, in-zone quests appear in their normal category (e.g. Dailies, Campaign). |
| `/horizon test` | Populate sample data to preview your styling. |
| `/horizon reset` | Clear test data and return to live objectives. |
| `/horizon resetpos` | Snap the tracker back to its default screen position. |
| `/horizon mplusdebug` | Toggle the Mythic+ block preview with example timer, completion %, and affixes so you can tune its appearance outside a dungeon. |
| `/horizon presence` | Presence test commands. Use `zone`, `subzone`, `discover`, `level`, `boss`, `ach`, `quest`, `scenario`, `wq`, `wqaccept`, `accept`, `update`, or `all` for a demo reel. |

### 🎛️ Settings Panel

* **Cinematic Options Panel** – Modern, minimalistic design with soft edges, subtle dividers, and a dark low-contrast palette. The search bar features a spyglass icon, integrated clear button, and focus-state styling.
* **Organized Configuration** – Settings are grouped into nine categories: **Modules** (enable or disable each suite; Focus is the objective tracker), **Layout** (panel behaviour, dimensions), **Visibility** (instance, combat, filtering), **Display** (header, list options; option to show or hide the Options button), **Features** (world quests, achievements, endeavors, decor, rare bosses, floating quest item, Mythic+, scenario & Delve), **Typography** (font, sizes, outline, text case, shadow), **Appearance** (panel backdrop/border, highlight), **Colors** (per-category colours with collapsible groups and per-group reset buttons; Grouping Overrides for Current Zone and Ready to Turn in; global colours), and **Organization** (Focus category order: apply a preset—Collection, Quest, Campaign, or World/Rare Focused—or drag to reorder all categories; Focus sort mode: Alphabetical, Quest Type, Zone, or Quest Level; behaviour toggles: Auto-track accepted quests, Require Ctrl for focus & remove, Require Ctrl for click to complete, Animations, Objective progress flash, Suppress untracked until reload). See in-game options for the full list.
* **Smart Search** – Use the **search bar** to find any setting—type at least two characters to see matching results, then click a result to jump directly to that option. Press Escape to clear the search.
* **Key Bind & Visibility Hooks** – Key bindings for **Collapse Tracker** and **Toggle Nearby Group** can be set under *Key Bindings → Horizon Suite*. The option "Show Nearby (Current Zone) group" in Display → List controls the same Nearby grouping. "Show category headers when collapsed" (Display → List) keeps section headers (Campaign, World Quests, etc.) visible when the tracker is collapsed; click a header to expand that category.

### Mouse Bindings
* **Left-Click**: Focus the quest (map pin). For auto-complete quests (those that can be finished without an NPC), left-click completes them directly. If the quest is not yet tracked, it is added to the tracker first. For world quests, left-click focuses without changing the watch list. For achievements, left-click opens the achievement panel. For Endeavors, left-click opens the housing dashboard to that endeavor. For Decor, left-click opens the decor catalog to that item.
* **Alt+Left-Click**: For Decor, opens a quick preview panel.
* **Shift+Left-Click**: Open Quest Log and map details for the quest. For world quests, this also adds the world quest to the watch list so it remains visible across zones. For Decor, opens the map to where the decor drops.
* **Right-Click**: If the quest is currently focused, clear the focus (remove the map pin) but keep it tracked; otherwise untrack/remove the quest from the tracker. Also hides in-zone world quests, weeklies and dailies until you change zone (or until reload if "Suppress untracked until reload" is on in Organization → Behaviour). For achievements, right-click removes the achievement from tracking. For Endeavors and Decor, right-click removes the item from tracking.
* **Shift+Right-Click**: Abandon the quest (with confirmation). World quests are excluded—Shift+Right on a world quest only untracks it.
* **Drag & Drop**: Reorder categories or resize the panel via the corner grip.

When **Require Ctrl for focus & remove** is enabled under **Options → Organization → Behaviour**, quest add/remove actions require Ctrl:

* **Ctrl+Left-Click**: Focus/add quests (including adding untracked quests to the tracker).
* **Ctrl+Right-Click**: Unfocus the quest if focused, or untrack/remove it from the tracker (including hiding in-zone weeklies/dailies until zone change).
* **Shift+Left-Click**: Still opens Quest Log & Map without needing Ctrl; for world quests, Ctrl+Shift+Left also adds them to the watch list.
* **Shift+Right-Click**: Still abandons non-world quests (with confirmation); world quests only untrack.

When **Require Ctrl for click to complete** is enabled, completing auto-complete quests requires **Ctrl+Left-Click** instead of plain Left-Click.

---

## 🗺️ Roadmap

Additional suites are planned as pluggable modules in the same spirit: clean, cinematic, and player-driven.

* **Horizon Focus** — Quest Log
* **Horizon Vista** — Minimap
* **Horizon Yield** — Loot / Gathering Hub
* **Horizon Presence** — Zone Text
* **Horizon Pulse** — Combat Reports / Alerts
* **Horizon Essence** — Unit Frames
* **Horizon Insight** — Tooltips
* **Horizon Verse** — Chat

---

## 📥 Installation

Requires World of Warcraft: Retail (The War Within or later).

1. Download the latest release and extract the `HorizonSuite` folder. (Beta testers: [rolling beta from main](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta).)
2. Place it in your `World of Warcraft\_retail_\Interface\AddOns\` directory.
3. Enable **Horizon Suite** in your AddOn list.
4. Type `/horizon options` to begin tailoring your experience.

---

## 💖 Support the Project

Horizon is built for players who value an intentional, clean UI. If the suite has improved your journey through Azeroth, consider supporting its development for the Midnight expansion.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/T6T71TX1Y1)

**[Support me on Patreon](https://patreon.com/HorizonSuite?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink)**

**[Join the Discord](https://discord.gg/RkkYJgB3PA)** — Bug reports, feature requests, and community discussion.

---

## Contributing

**Bug reports & feature requests** — Use [GitHub Issues](https://github.com/Crystilac93/Horizon-Suite/issues). Choose the Bug report or Feature request template for structured intake. Reports from Discord, Reddit, or CurseForge are also welcome; you can paste them into a new issue.

**Pull requests** — Contributions are welcome. Use the PR template and include `Closes #N` in the description to link your PR to an issue. When merged, linked issues auto-close and the beta build updates automatically.

**Labels** — Issues use labels for type (`bug`, `feature`, `improvement`), module (`Focus`, `Presence`, `Vista`, etc.), and priority (`Priority 0`, `Priority 1`, `Priority 2`). Filter by label to find issues to work on.

---

## Contributors

Thanks to everyone who has contributed to Horizon Suite:

* **feanor21#2847** — Panoramuxa (Tarren Mill -EU)

---

## License
Distributed under the MIT License. See `LICENSE` for more information.
