# 🌌 Horizon Suite

[![Release](https://img.shields.io/github/v/release/Crystilac93/Horizon-Suite?display_name=release)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Release Date](https://img.shields.io/github/release-date-pre/Crystilac93/Horizon-Suite)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Beta](https://img.shields.io/github/release-date-pre/Crystilac93/Horizon-Suite?label=beta&color=orange)](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta)

[![Discord](https://img.shields.io/discord/1471477531805749412?label=Discord&labelColor=%237289da)](https://discord.gg/MndCSYQ2ra) [![Patreon](https://img.shields.io/badge/build-donate-orange?label=patreon)](https://www.patreon.com/c/HorizonSuite) [![Ko-fi](https://img.shields.io/badge/build-tip-purple?label=Ko-fi)](https://ko-fi.com/horizonsuite) 

**Horizon Suite** is a core addon with pluggable modules: **Focus** (objective tracker), **Presence** (zone text & notifications), **Horizon Insight** (cinematic tooltips), and **Yield** (loot toasts). Designed for the Midnight era—clean, cinematic, player-in-control. It replaces static, cluttered lists with a fluid interface that grants you total agency over your goals. Additional suites will appear as modules in the same options panel.

---

## 🎯 Focus (Objective Tracker)

![Focus - Objective Tracker](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Focus.png)

- **Smart zone tracking** – Nearby quests float to the top; list updates as you move. Delves, scenarios, raids, and world events get their own sections with progress bars and timers.
- **Track what matters** – Achievements, Endeavors (housing), Decor, and Traveler's Log objectives appear in the tracker. One-click to open achievement panel, housing dashboard, decor catalog, or Adventure Guide.
- **Rare boss alerts** – Super-track nearby rares with one click and optional audio alerts.
- **Live quest sync** – World quests, dailies, and weeklies update dynamically. Quests auto-track when you accept them. Choose a radar icon for auto-tracked in-zone entries.
- **All The Things integration** – Collection data appears directly in your objectives.
- **Profiles** – Create, switch, copy, and delete named profiles. Per-character, per-specialization, or global (account-wide) modes. Import and export profiles as shareable text strings.
- **Combat-ready** – Show, fade, or hide in combat; show or hide in dungeons/raids/BGs; compact or super-minimal layouts.
- **Show only on mouseover** – Fade the tracker when not hovering; move the mouse over it to reveal.
- **Mythic+ and Delves** – Banner for keystone info, timer, and affixes. Delve objectives in the standard layout.

## 🎬 Presence (Zone Text & Notifications)

![Presence - Zone Text & Notifications](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Presence.png)

- **Cinematic notifications** – Zone text, subzone changes, "Discovered" lines. Level-up, boss emotes, achievements, quest accept/complete, scenario start, and objective progress in delves/scenarios appear as styled toasts with smooth animations.

## 💎 Yield (Loot Toasts) - BETA

- **Cinematic loot notifications** – Items, money, currency, and reputation gains appear as styled toasts with quality-based colours and smooth slide-in animations.
- **Epic and legendary flair** – Extra entrance time, shine effects, and optional sounds for high-value loot.

## 🔍 Horizon Insight (Tooltips)

- **Cinematic tooltips** – Dark backdrop, class-colored player names and borders, faction icons, spec/role display, and fade-in animation.
- **Profile-backed settings** – Anchor mode (cursor or fixed) and position stored per profile.
- **Quick options** – `/insight` or `/mtt` for anchor toggle, move, reset, and test.

## 🎨 Visuals & UI Design

- **High-fidelity icons** – Distinct icons for Campaign, Legendary, and World Quests.
- **Customizable colours** – Per-category colour control (title, objective, zone, section). Panel backdrop colour and opacity.
- **Typography and spacing** – Fonts, sizes, outlines, and spacing sliders. Optional SharedMedia support for fonts from addon packs. Turn-in highlights and progress counts (e.g. 15/18) at a glance.
- **Fluid motion** – Smooth entry/exit animations and a subtle pulse on objective completion.

---

## ⌨️ Basic Commands


| Command              | Action                                          |
| -------------------- | ----------------------------------------------- |
| `/horizon options`   | Open the options panel (search bar included).   |
| `/horizon toggle`    | Toggle the tracker on or off.                   |
| `/horizon collapse`  | Collapse or expand the tracker.                 |
| `/horizon nearby`    | Toggle the Nearby (Current Zone) grouping.      |
| `/horizon test`      | Preview your styling with sample data.          |
| `/horizon reset`     | Clear test data.                                |
| `/horizon resetpos`  | Reset the tracker position.                     |
| `/horizon yield`     | Show Yield (loot toast) help and test commands. |
| `/horizon yield all` | Demo reel of all loot toast types.              |
| `/insight` or `/mtt` | Horizon Insight tooltip options (anchor, move, reset, test). |


**Mouse:** Left-click to focus a quest (and complete auto-complete quests). Right-click to untrack. Shift+left-click for quest log and map. Shift+right-click to abandon. Drag the corner grip to resize.

---

## 📦 Modules & Roadmap

**Focus** is the objective tracker. **Presence** adds cinematic zone text and notifications. **Horizon Insight** adds cinematic tooltips with class colors, spec display, and faction icons. **Yield** adds cinematic loot toasts (items, money, currency, reputation). Enable them in options. More modules are planned: Quest Log, Minimap, Combat Alerts, Unit Frames, Chat.

---

## 📥 Installation & Support

**Requirements:** World of Warcraft Retail (The War Within or later).

**Optional:** [SharedMedia](https://www.curseforge.com/wow/addons/sharedmedia) (e.g. SharedMedia Additional Fonts) for expanded font choices in the Typography options. If not installed, the font dropdown shows only Game Font and any custom path you enter.

1. Install via [CurseForge](https://www.curseforge.com/projects/1457844), [Wago](https://addons.wago.io/addons/jK8gY56y), or download the [latest release](https://github.com/Crystilac93/Horizon-Suite/releases) and extract the `HorizonSuite` folder. ([Beta](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta))
2. Place it in `World of Warcraft\_retail_\Interface\AddOns\`.
3. Enable **Horizon Suite** in your AddOn list.
4. Type `/horizon options` to customize.

[ko-fi](https://ko-fi.com/T6T71TX1Y1) **[Patreon](https://patreon.com/HorizonSuite?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink)** | **[Discord](https://discord.gg/RkkYJgB3PA)** — Bug reports, feature requests, and community.

---

## 🤝 Contributing

**Issues** — [GitHub Issues](https://github.com/Crystilac93/Horizon-Suite/issues). Use the Bug report or Feature request template. Reports from Discord, Reddit, or CurseForge are welcome.

---

## 💖 Contributors

Thanks to everyone who has contributed to Horizon Suite:

- **feanor21#2847 — Panoramuxa (Tarren Mill -EU)** — Development
- **Aishuu** — French localization (frFR)
- **아즈샤라-두녘** — Korean localization (koKR)
- **Linho-Gallywix** — Brazilian Portuguese localization (ptBR)

---

## 🌐 Localizations

The options panel is localized for:

- **French (frFR)** — `options/frFR.lua`
- **Korean (koKR)** — `options/koKR.lua`
- **Brazilian Portuguese (ptBR)** — `options/ptBR.lua`

Contributions for additional locales are welcome via discord request.

---

## License

Distributed under the MIT License. See `LICENSE` for more information.