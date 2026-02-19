# 🌌 Horizon Suite

**Horizon Suite** is a core addon with pluggable modules: **Focus** (objective tracker) and **Presence** (zone text & notifications). Designed for the Midnight era—clean, cinematic, player-in-control. It replaces static, cluttered lists with a fluid interface that grants you total agency over your goals. Additional suites will appear as modules in the same options panel.

![Horizon Suite Preview](https://github.com/user-attachments/assets/72072df2-7ba3-4205-a984-df561eaf3ed4)

---

## 🧠 Intelligent Logic
The systems driving your efficiency.

* **Spatial Awareness** – Automatically filters quests by zone and floats nearby objectives to the top. Tracks sub-zones and micro-dungeons instantly without requiring a map refresh. The Nearby (Current Zone) grouping can be toggled on or off via keybind, `/horizon nearby`, or Display → List.
* **Dynamic Scanning** – Surfaces active Scenarios, Delves, and World Events in dedicated, high-priority sections. Includes support for cinematic progress bars, timers, and difficulty tiers.
* **Rare Boss Tracker** – Scans for nearby vignettes, allowing you to super-track rares with a single click and optional audio alerts.
* **Achievement Tracking** – Tracked achievements appear in a dedicated Achievements section. Left-click opens the achievement panel; right-click removes it from tracking. Toggle visibility in Features → Achievements. Completed achievements are hidden by default; enable "Show completed achievements" to include them. Use "Show achievement icons" to toggle achievement icons independently of quest type icons.
* **Live Sync** – World Quests, Dailies, and Weeklies update dynamically so you never miss a pickup. Dailies available to accept but not yet accepted show an "— Available" label. Dungeon objectives are supported and appear in the tracker. The world quest list is re-evaluated when you move between zones.
* **Secure Quest Items** – High-performance quest item buttons built on secure templates, ensuring they work flawlessly mid-fight without UI errors.
* **ATT Integration** – Full native support for **All The Things**, displaying collection data directly within your objectives.
* **Presence Notifications** – Cinematic zone text, subzone changes, and "Discovered" lines. Level-up, boss emotes, achievements, quest accept/complete/update, world quest accept, and world quest complete banners appear as styled notifications with priority queueing and smooth entrance/exit animations. Off by default (still being refined); enable in Modules → Enable Presence module if desired.

---

## 🎨 Visuals & UI Design
An aesthetic that complements the modern game client.

* **Visual Hierarchy** – High-fidelity icons for Campaign, Legendary, and World Quests.
* **Turn-In Guidance** – Quests "Ready for Turn-in" receive a unique, high-contrast visual highlight and priority positioning, giving you a clear signal to head back to the hub.
* **The Color Matrix** – Define your own aesthetic with per-category colour customization (Title, Objective, Zone, Section) via `/horizon options`. Each category group is collapsible with a reset button. Current Zone and Ready to Turn in colours are grouped under Grouping Overrides.
* **Typography Suite** – Total control over fonts, sizes, outlines, and text shadows for Headers, Titles, and Objectives. Optional text case: set the main OBJECTIVES header, section headers and quest titles to Lower Case, Upper Case, or Proper (title case).
* **Fluid Motion** – Smooth entry/exit animations, a subtle "pulse" on objective completion, and adaptive layouts that support "Grow Upward" anchoring.

---

## ⚔️ Performance & Utility
Built for the heat of gameplay.

* **Hide in Combat** – Maintain total focus during encounters. The tracker can be set to automatically vanish the moment you enter combat, clearing your screen for boss mechanics and reappearing instantly once the fight is over.
* **Mythic+ Integration** – Cinematic banner for dungeon name, keystone level, timer, completion %, and affixes. Hover the banner to see detailed modifier descriptions.
* **Instance Visibility** – Granular control over where the tracker appears. Choose to show or hide the interface specifically for Dungeons, Raids, Battlegrounds, or Arenas. Filter by zone to hide quests outside your current zone entirely.
* **Compact & Minimal Modes** – Optimize your screen real estate with granular spacing sliders (Display → Spacing: entries, category headers, objectives), "Super-Minimal" headers (hides the OBJECTIVES header and quest count for a pure text list), and backdrop opacity controls. Super-minimal mode keeps a thin bar with expand/collapse and options (shown on hover) so you can open options and expand when starting collapsed. Header count format (Display → Header): choose **Tracked / in log** (e.g. 4/19, default) or **In log / max slots** (e.g. 19/35); tracked excludes world/live-in-zone quests.

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
| `/horizon presence` | Presence test commands. Use `zone`, `subzone`, `discover`, `level`, `boss`, `ach`, `quest`, `wq`, `wqaccept`, `accept`, `update`, or `all` for a demo reel. |

### 🎛️ Settings Panel

* **Cinematic Options Panel** – Modern, minimalistic design with soft edges, subtle dividers, and a dark low-contrast palette. The search bar features a spyglass icon, integrated clear button, and focus-state styling.
* **Organized Configuration** – Settings are grouped into nine categories: **Modules** (enable or disable each suite; Focus is the objective tracker), **Layout** (panel behaviour, dimensions), **Visibility** (instance, combat, filtering), **Display** (header, list options), **Features** (achievements, rare bosses, floating quest item, Mythic+, scenario & Delve), **Typography** (font, sizes, outline, text case, shadow), **Appearance** (panel backdrop/border, highlight), **Colors** (per-category colours with collapsible groups and per-group reset buttons; Grouping Overrides for Current Zone and Ready to Turn in; global colours), and **Organization** (Focus category order via drag-and-drop; Focus sort mode: Alphabetical, Quest Type, Zone, or Quest Level; behaviour toggles: Require Ctrl, Animations, Objective progress flash). See in-game options for the full list.
* **Smart Search** – Use the **search bar** to find any setting—type at least two characters to see matching results, then click a result to jump directly to that option. Press Escape to clear the search.
* **Key Bind & Visibility Hooks** – Key bindings for **Collapse Tracker** and **Toggle Nearby Group** can be set under *Key Bindings → Horizon Suite*. The option "Show Nearby (Current Zone) group" in Display → List controls the same Nearby grouping. "Show category headers when collapsed" (Display → List) keeps section headers (Campaign, World Quests, etc.) visible when the tracker is collapsed; click a header to expand that category.

### Mouse Bindings
* **Left-Click**: Focus the quest (map pin). If the quest is not yet tracked, it is added to the tracker first. For world quests, left-click focuses without changing the watch list. For achievements, left-click opens the achievement panel.
* **Shift+Left-Click**: Open Quest Log and map details for the quest. For world quests, this also adds the world quest to the watch list so it remains visible across zones.
* **Right-Click**: If the quest is currently focused, clear the focus (remove the map pin) but keep it tracked; otherwise untrack/remove the quest from the tracker. For achievements, right-click removes the achievement from tracking.
* **Shift+Right-Click**: Abandon the quest (with confirmation).
* **Drag & Drop**: Reorder categories or resize the panel via the corner grip.

When **Require Ctrl for focus & remove** is enabled under **Options → Organization → Behaviour**, quest add/remove actions require Ctrl:

* **Ctrl+Left-Click**: Focus/add quests (including adding untracked quests to the tracker).
* **Ctrl+Right-Click**: Unfocus the quest if focused, or untrack/remove it from the tracker.
* **Shift+Left-Click**: Still opens Quest Log & Map without needing Ctrl; for world quests, Ctrl+Shift+Left also adds them to the watch list.
* **Shift+Right-Click**: Still abandons quests (with confirmation).

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

1. Download the latest release and extract the `HorizonSuite` folder.
2. Place it in your `World of Warcraft\_retail_\Interface\AddOns\` directory.
3. Enable **Horizon Suite** in your AddOn list.
4. Type `/horizon options` to begin tailoring your experience.

---

## 💖 Support the Project

Horizon is built for players who value an intentional, clean UI. If the suite has improved your journey through Azeroth, consider supporting its development for the Midnight expansion.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/T6T71TX1Y1)

**[Join the Discord](https://discord.gg/RkkYJgB3PA)** — Bug reports, feature requests, and community discussion.

---

## License
Distributed under the MIT License. See `LICENSE` for more information.
