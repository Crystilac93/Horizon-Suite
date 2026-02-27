# 🌌 Horizon Suite

[![Release](https://img.shields.io/github/v/release/Crystilac93/Horizon-Suite)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Release Date](https://img.shields.io/github/release-date/Crystilac93/Horizon-Suite)](https://github.com/Crystilac93/Horizon-Suite/releases) [![Beta](https://img.shields.io/github/release-date-pre/Crystilac93/Horizon-Suite?label=Beta&color=orange)](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta)

[![Discord](https://img.shields.io/discord/1471477531805749412?label=Discord&labelColor=%237289da)](https://discord.gg/MndCSYQ2ra) [![Patreon](https://img.shields.io/badge/build-donate-orange?label=patreon)](https://www.patreon.com/c/HorizonSuite) [![Ko-fi](https://img.shields.io/badge/build-tip-purple?label=Ko-fi)](https://ko-fi.com/horizonsuite)

**Horizon Suite** is a core addon with pluggable modules: **Focus** (objective tracker), **Presence** (zone text & notifications), **Insight** (cinematic tooltips), **Vista** (minimap), and **Yield** (loot toasts). Designed for the Midnight era—clean, cinematic, player-in-control. It replaces static, cluttered lists with a fluid interface that grants you total agency over your goals. Additional suites will appear as modules in the same options panel.

---

## 🎯 Focus (Objective Tracker)

![Focus - Objective Tracker](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Focus.gif)

- **Smart zone tracking** – Nearby quests float to the top; list updates as you move. Delves, scenarios, raids, and world events get their own sections with progress bars and timers.
- **Track what matters** – Achievements, Endeavors (housing), Decor, and Traveler's Log objectives appear in the tracker. Full achievement progress tracking with criteria parsing and quantity strings. One-click to open achievement panel, housing dashboard, decor catalog, or Adventure Guide.
- **Rare boss alerts** – Super-track nearby rares with one click and optional audio alerts.
- **Live quest sync** – World quests, dailies, and weeklies update dynamically. Quests auto-track when you accept them. Choose a radar icon for auto-tracked in-zone entries.
- **All The Things integration** – Collection data appears directly in your objectives.
- **Profiles** – Create, switch, copy, and delete named profiles. Per-character, per-specialization, or global (account-wide) modes. Import and export profiles as shareable text strings.
- **Combat-ready** – Show, fade, or hide in combat; show or hide in dungeons/raids/BGs; compact or super-minimal layouts.
- **Show only on mouseover** – Fade the tracker when not hovering; move the mouse over it to reveal.
- **Mythic+ and Delves** – Banner for keystone info, timer, and affixes. Delve objectives in the standard layout.
- **Classic click behaviour** – Optional toggle: left-click opens the quest map, right-click shows share/abandon menu. When off, Ctrl+Right shares the quest with your party.

## 🎬 Presence (Zone Text & Notifications)

![Presence - Zone Text & Notifications](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Presence.gif)

- **Cinematic notifications** – Replaces Blizzard's default zone text, level-up banner, boss emote frame, and achievement alerts with styled toasts: smooth entrance and exit animations, a dividing line between title and subtitle, and an optional "Discovered!" third line on first visits.
- **Full notification coverage** – Zone entry, subzone changes, level-up, boss emotes, achievements, quest accepted/complete/progress, world quest accepted/complete, scenario start, and scenario or delve objective updates — 12 types in total.
- **Per-type toggles** – Enable or disable each notification type individually. Mythic+ suppression silences zone, quest, and scenario notifications while inside a keystone dungeon.
- **Prioritised queue** – Up to five notifications queue when one is already playing; higher-priority events (level-up, boss emotes, achievements) play ahead of routine quest updates.
- **Visual customisation** – Vertical screen position, frame scale, and independent font types and sizes for title and subtitle. Entrance speed, exit speed, and hold-duration multiplier are all adjustable.

## 🗺️ Vista (Minimap)

![Vista - Minimap](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Vista.gif)

- **Square or circular minimap** – Choose a square or circular mask. Adjust size (100–400px), lock position, or drag to relocate. Optional auto zoom-out after zooming.
- **Zone text, coordinates, and time** – Zone name, player coordinates, and game time below the minimap. Each element has its own font, size, and colour; show or hide individually. Click the time to open the stopwatch.
- **Instance difficulty** – Difficulty name and Mythic+ keystone level shown when in an instance.
- **Mail and queue indicators** – New mail icon and queue status button appear automatically when relevant.
- **Built-in buttons** – Tracking, calendar, and zoom (+/−) buttons. Show always or on mouseover. Each is draggable and resizable; lock to prevent accidental movement.
- **Addon button collector** – Minimap buttons from other addons are grouped and presented in one of three modes: mouseover bar below the minimap, right-click panel, or floating drawer button. Per-addon filter to show only selected buttons.
- **Customizable appearance** – Border (thickness, colour, opacity), panel background and border colours for button panels, and per-element typography. SharedMedia support for fonts.
- **Mouse wheel zoom** – Scroll over the minimap to zoom in and out.

## 💎 Yield (Loot Toasts) - BETA

![Yield - Loot Toasts](https://raw.githubusercontent.com/Crystilac93/Horizon-Suite/main/docs/Yield.gif)

- **Cinematic loot notifications** – Items, money, currency, and reputation gains appear as styled toasts with quality-based colours and smooth slide-in animations.
- **Epic and legendary flair** – Extra entrance time, shine effects, and optional sounds for high-value loot.

## 🔍 Insight (Tooltips) - BETA

- **Cinematic tooltips** – Dark backdrop, class-colored player names and borders, faction icons, spec/role display, and fade-in animation.
- **Profile-backed settings** – Anchor mode (cursor or fixed) and position stored per profile.

## 🎨 Visuals & UI Design

- **High-fidelity icons** – Distinct icons for Campaign, Legendary, and World Quests.
- **Customizable colours** – Per-category colour control (title, objective, zone, section). Panel backdrop colour and opacity.
- **Scaling** – Global UI scale (50–200%) for all modules, or per-module sliders for Focus, Presence, Vista, Insight, and Yield when WoW UI scale is lowered.
- **Typography and spacing** – Fonts, sizes, outlines, and spacing sliders. Optional SharedMedia support for fonts from addon packs. Turn-in highlights and progress counts (e.g. 15/18) at a glance.
- **Progress bar** – Optional bar under objectives with numeric progress (e.g. 3/250). Configurable font, size, and colours.
- **Fluid motion** – Smooth entry/exit animations and a subtle pulse on objective completion.
- **Scroll indicators** – Optional fade or arrow buttons when the list has more content than visible.

---

## ⌨️ Basic Commands

| Command | Description |
|---------|-------------|
| **/h**, **/hopt**, **/hedit** | Core — help, options, edit screen |
| **/h focus** toggle, collapse, nearby, resetpos | Tracker — enable/disable, collapse, toggle Nearby group, reset position |
| **/h vista** reset, toggle, lock, scale | Minimap — reset position, show/hide, lock, set scale |
| **/h yield** edit, reset, toggle | Loot toasts — reposition, reset position, enable/disable |
| **/h insight** anchor, move, resetpos | Tooltips — anchor mode, reposition, reset position |

---

## 📦 Modules & Roadmap

**Focus** is the objective tracker. **Presence** adds cinematic zone text and notifications. **Insight** adds cinematic tooltips with class colors, spec display, and faction icons. **Vista** adds a cinematic minimap (square or circular) with zone text, coordinates, addon button collector, and full customisation. **Yield** adds cinematic loot toasts (items, money, currency, reputation). Enable them in options. More modules are planned: Quest Log, Combat Alerts, Unit Frames, Chat.

---

## 📥 Installation & Support

**Requirements:** World of Warcraft Retail (The War Within or later).

**Optional:** [SharedMedia](https://www.curseforge.com/wow/addons/sharedmedia) (e.g. SharedMedia Additional Fonts) for expanded font choices in the Typography options. If not installed, the font dropdown shows only Game Font and any custom path you enter.

1. Install via [CurseForge](https://www.curseforge.com/projects/1457844), [Wago](https://addons.wago.io/addons/jK8gY56y), or download the [latest release](https://github.com/Crystilac93/Horizon-Suite/releases) and extract the `HorizonSuite` folder. ([Beta](https://github.com/Crystilac93/Horizon-Suite/releases/tag/beta))
2. Place it in `World of Warcraft\_retail_\Interface\AddOns\`.
3. Enable **Horizon Suite** in your AddOn list.
4. Type `/h options` or `/hopt` to customize.

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
- **Russian (ruRU)** — `options/ruRU.lua`
- **Spanish (esES)** — `options/esES.lua`

Contributions for additional locales are welcome via discord request.

---

## License

Distributed under the MIT License. See `LICENSE` for more information.
