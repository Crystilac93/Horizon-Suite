if GetLocale() ~= "frFR" then return end

local addon = _G.HorizonSuite
if not addon then return end

local L = setmetatable({}, { __index = function(t, k) return k end })
addon.L = L
addon.StandardFont = UNIT_NAME_FONT

-- =====================================================================
-- OptionsPanel.lua — Title
-- =====================================================================
L["HORIZON SUITE"]                                                  = "HORIZON SUITE"

-- =====================================================================
-- OptionsPanel.lua — Sidebar module group labels
-- =====================================================================
L["Focus"]                                                          = "Paramètres du suivi"
L["Presence"]                                                       = "Paramètres des notifications"
L["Other"]                                                          = "Autre"

-- =====================================================================
-- OptionsPanel.lua — Section headers
-- =====================================================================
L["Quest types"]                                                    = "Types de quêtes"
L["Element overrides"]                                              = "Couleurs par élément"
L["Per category"]                                                   = "Couleurs par catégorie"
L["Grouping Overrides"]                                             = "Couleurs prioritaires"
L["Other colors"]                                                   = "Autres couleurs"

-- =====================================================================
-- OptionsPanel.lua — Color row labels (collapsible group sub-rows)
-- =====================================================================
L["Section"]                                                        = "Section"
L["Title"]                                                          = "Titre"
L["Zone"]                                                           = "Zone"
L["Objective"]                                                      = "Objectif"

-- =====================================================================
-- OptionsPanel.lua — Toggle switch labels & tooltips
-- =====================================================================
L["Ready to Turn In overrides base colours"]                        = "Prêt à rendre remplace les couleurs de base"
L["Ready to Turn In uses its colours for quests in that section."]  = "Les quêtes disponibles à rendre utilisent leurs couleurs dans cette section."
L["Current Zone overrides base colours"]                            = "Zone actuelle remplace les couleurs de base"
L["Current Zone uses its colours for quests in that section."]      = "Les quêtes de la zone actuelle utilisent leurs couleurs dans cette section."
L["Use distinct color for completed objectives"]                     = "Couleur distincte pour les objectifs terminés"
L["When on, completed objectives (e.g. 1/1) use the color below; when off, they use the same color as incomplete objectives."] = "Activé : les objectifs terminés (ex. 1/1) utilisent la couleur ci-dessous. Désactivé : ils utilisent la même couleur que les objectifs incomplets."
L["Completed objective"]                                           = "Objectif terminé"

-- =====================================================================
-- OptionsPanel.lua — Button labels
-- =====================================================================
L["Reset"]                                                          = "Réinitialiser"
L["Reset quest types"]                                              = "Réinitialiser les types de quêtes"
L["Reset overrides"]                                                = "Réinitialiser les couleurs personnalisées"
L["Reset to defaults"]                                              = "Réinitialiser les valeurs par défaut"
L["Reset to default"]                                               = "Réinitialiser la valeur par défaut"

-- =====================================================================
-- OptionsPanel.lua — Search bar placeholder
-- =====================================================================
L["Search settings..."]                                             = "Rechercher dans les paramètres..."
L["Search fonts..."]                                                 = "Rechercher une police..."

-- =====================================================================
-- OptionsPanel.lua — Resize handle tooltip
-- =====================================================================
L["Drag to resize"]                                                 = "Glisser pour redimensionner"

-- =====================================================================
-- OptionsData.lua Category names (sidebar)
-- =====================================================================
L["Modules"]                                            = "Modules"
L["Layout"]                                             = "Disposition"
L["Visibility"]                                         = "Visibilité"
L["Display"]                                            = "Affichage"
L["Features"]                                           = "Fonctionnalités"
L["Typography"]                                         = "Typographie"
L["Appearance"]                                         = "Apparence"
L["Colors"]                                             = "Couleurs"
L["Organization"]                                       = "Organisation"

-- =====================================================================
-- OptionsData.lua Section headers
-- =====================================================================
L["Panel behaviour"]                                    = "Comportement du panneau"
L["Dimensions"]                                         = "Dimensions"
L["Instance"]                                           = "Instance"
L["Combat"]                                             = "Combat"
L["Filtering"]                                          = "Filtrage"
L["Header"]                                             = "En-tête"
L["List"]                                               = "Liste"
L["Spacing"]                                            = "Espacement"
L["Rare bosses"]                                        = "Boss rares"
L["World quests"]                                       = "Quêtes mondiales"
L["Floating quest item"]                                = "Objet de quête flottant"
L["Mythic+"]                                            = "Mythique+"
L["Achievements"]                                       = "Hauts faits"
L["Endeavors"]                                          = "Défis"
L["Decor"]                                              = "Décoration"
L["Scenario & Delve"]                                   = "Scénario et exploration"
L["Font"]                                               = "Police"
L["Text case"]                                          = "Casse"
L["Shadow"]                                             = "Ombre"
L["Panel"]                                              = "Panneau"
L["Highlight"]                                          = "Surlignage"
L["Color matrix"]                                       = "Matrice de couleurs"
L["Focus order"]                                        = "Ordre de Focus"
L["Sort"]                                               = "Tri"
L["Behaviour"]                                          = "Comportement"

-- =====================================================================
-- OptionsData.lua Modules
-- =====================================================================
L["Enable Focus module"]                                = "Activer le module Focus"
L["Show the objective tracker for quests, world quests, rares, achievements, and scenarios."] = "Affiche le suivi des objectifs pour les quêtes, quêtes mondiales, boss rares, hauts faits et scénarios."
L["Enable Presence module"]                             = "Activer le module Presence"
L["Cinematic zone text and notifications (zone changes, level up, boss emotes, achievements, quest updates)."] = "Texte de zone cinématique et notifications (changement de zone, montée de niveau, émojis de boss, hauts faits, mises à jour de quêtes)."
L["Enable Yield module"]                                = "Activer le module Yield"
L["Cinematic loot notifications (items, money, currency, reputation)."] = "Notifications de butin cinématiques (objets, argent, monnaies, réputation)."
L["Yield"]                                              = "Yield"
L["General"]                                            = "Général"
L["Position"]                                           = "Position"
L["Reset position"]                                     = "Réinitialiser la position"
L["Reset loot toast position to default."]              = "Réinitialiser la position des notifications de butin."

-- =====================================================================
-- OptionsData.lua Layout
-- =====================================================================
L["Lock position"]                                      = "Verrouiller la position"
L["Prevent dragging the tracker."]                      = "Empêche de déplacer le suivi."
L["Grow upward"]                                        = "Grandir vers le haut"
L["Anchor at bottom so the list grows upward."]         = "Ancré en bas pour que la liste grandisse vers le haut."
L["Start collapsed"]                                    = "Commencer replié"
L["Start with only the header shown until you expand."] = "N'afficher que l'en-tête jusqu'à ce que vous agrandissiez."
L["Panel width"]                                        = "Largeur du panneau"
L["Tracker width in pixels."]                           = "Largeur du suivi en pixels."
L["Max content height"]                                 = "Hauteur max du contenu"
L["Max height of the scrollable list (pixels)."]        = "Hauteur maximale de la liste défilable (pixels)."

-- =====================================================================
-- OptionsData.lua Visibility
-- =====================================================================
L["Always show M+ block"]                                           = "Toujours afficher le bloc M+"
L["Show the M+ block whenever an active keystone is running"]       = "Affiche le bloc M+ dès qu'une clé runique est active."
L["Show in dungeon"]                                    = "Afficher en donjon"
L["Show tracker in party dungeons."]                    = "Affiche le suivi dans les donjons de groupe."
L["Show in raid"]                                       = "Afficher en raid"
L["Show tracker in raids."]                             = "Affiche le suivi en raid."
L["Show in battleground"]                               = "Afficher en champ de bataille"
L["Show tracker in battlegrounds."]                     = "Affiche le suivi en champs de bataille."
L["Show in arena"]                                      = "Afficher en arène"
L["Show tracker in arenas."]                            = "Affiche le suivi en arènes."
L["Hide in combat"]                                     = "Masquer en combat"
L["Hide tracker and floating quest item in combat."]    = "Masque le suivi et l'objet de quête flottant en combat."
L["Mouseover"]                                          = "Survol"
L["Show only on mouseover"]                             = "Afficher au survol uniquement"
L["Fade tracker when not hovering; move mouse over it to show."] = "Estompe le suivi quand la souris n'est pas dessus ; survolez pour l'afficher."
L["Faded opacity"]                                      = "Opacité estompée"
L["How visible the tracker is when faded (0 = invisible)."] = "Visibilité du suivi quand estompé (0 = invisible)."
L["Only show quests in current zone"]                   = "Quêtes de la zone actuelle uniquement"
L["Hide quests outside your current zone."]             = "Masque les quêtes hors de votre zone actuelle."

-- =====================================================================
-- OptionsData.lua Display — Header
-- =====================================================================
L["Show quest count"]                                   = "Afficher le nombre de quêtes"
L["Show quest count in header."]                        = "Affiche le nombre de quêtes dans l'en-tête."
L["Header count format"]                                = "Format du compteur d'en-tête"
L["Tracked/in-log or in-log/max-slots. Tracked excludes world/live-in-zone quests."] = "Suivies/journal ou journal/max. Les suivies excluent les quêtes mondiales et de zone."
L["Show header divider"]                                = "Afficher le séparateur d'en-tête"
L["Show the line below the header."]                    = "Affiche la ligne sous l'en-tête."
L["Super-minimal mode"]                                 = "Mode ultra-minimal"
L["Hide header for a pure text list."]                  = "Masque l'en-tête pour une liste texte pure."
L["Show options button"]                               = "Afficher le bouton Options"
L["Show the Options button in the tracker header."]     = "Affiche le bouton Options dans l'en-tête du suivi."
L["Header color"]                                       = "Couleur de l'en-tête"
L["Color of the OBJECTIVES header text."]               = "Couleur du texte d'en-tête OBJECTIFS."
L["Header height"]                                      = "Hauteur de l'en-tête"
L["Height of the header bar in pixels (18–48)."]        = "Hauteur de la barre d'en-tête en pixels (18–48)."

-- =====================================================================
-- OptionsData.lua Display — List
-- =====================================================================
L["Show section headers"]                               = "Afficher les en-têtes de section"
L["Show category labels above each group."]             = "Affiche les libellés de catégorie au-dessus de chaque groupe."
L["Show category headers when collapsed"]               = "En-têtes de section visibles quand replié"
L["Keep section headers visible when collapsed; click to expand a category."] = "Garde les en-têtes visibles quand replié ; cliquez pour développer une catégorie."
L["Show Nearby (Current Zone) group"]                   = "Afficher le groupe Zone actuelle"
L["Show in-zone quests in a dedicated Current Zone section. When off, they appear in their normal category."] = "Affiche les quêtes de zone dans une section dédiée. Désactivé : elles apparaissent dans leur catégorie normale."
L["Show zone labels"]                                   = "Afficher les noms de zone"
L["Show zone name under each quest title."]             = "Affiche le nom de zone sous chaque titre de quête."
L["Active quest highlight"]                             = "Surlignage de la quête active"
L["How the focused quest is highlighted."]              = "Comment la quête active est surlignée."
L["Show quest item buttons"]                            = "Afficher les boutons d'objet de quête"
L["Show usable quest item button next to each quest."]  = "Affiche le bouton d'objet utilisable à côté de chaque quête."
L["Show objective numbers"]                             = "Afficher les numéros d'objectifs"
L["Prefix objectives with 1., 2., 3."]                  = "Préfixe les objectifs avec 1., 2., 3."
L["Show completed count"]                               = "Afficher le compteur de complétés"
L["Show X/Y progress in quest title."]                  = "Affiche la progression X/Y dans le titre de quête."
L["Use tick for completed objectives"]                  = "Coche pour les objectifs terminés"
L["When on, completed objectives show a checkmark (✓) instead of green color."] = "Activé : les objectifs terminés affichent une coche (✓) au lieu du vert."
L["Show entry numbers"]                                 = "Afficher les numéros d'entrée"
L["Prefix quest titles with 1., 2., 3. within each category."] = "Préfixe les titres de quêtes avec 1., 2., 3. dans chaque catégorie."
L["Completed objectives"]                               = "Objectifs terminés"
L["For multi-objective quests, how to display objectives you've completed (e.g. 1/1)."] = "Pour les quêtes multi-objectifs, affichage des objectifs terminés (ex. 1/1)."
L["Show all"]                                           = "Tout afficher"
L["Fade completed"]                                     = "Estomper les terminés"
L["Hide completed"]                                     = "Masquer les terminés"
L["Show '**' in-zone suffix"]                           = "Afficher le suffixe '**' en zone"
L["Append ** to world quests and weeklies/dailies that are not yet in your quest log (in-zone only)."] = "Ajoute ** aux quêtes mondiales et hebdomadaires/journalières non encore dans le journal (en zone uniquement)."

-- =====================================================================
-- OptionsData.lua Display — Spacing
-- =====================================================================
L["Compact mode"]                                       = "Mode compact"
L["Preset: sets entry and objective spacing to 4 and 1 px."] = "Préréglage : espacement des entrées et objectifs à 4 et 1 px."
L["Spacing between quest entries (px)"]                 = "Espacement entre les entrées (px)"
L["Vertical gap between quest entries."]                = "Espacement vertical entre les entrées de quête."
L["Spacing before category header (px)"]                = "Espacement avant l'en-tête (px)"
L["Gap between last entry of a group and the next category label."] = "Espace entre la dernière entrée d'un groupe et le libellé suivant."
L["Spacing after category header (px)"]                 = "Espacement après l'en-tête (px)"
L["Gap between category label and first quest entry below it."] = "Espace entre le libellé et la première entrée de quête en dessous."
L["Spacing between objectives (px)"]                    = "Espacement entre objectifs (px)"
L["Vertical gap between objective lines within a quest."] = "Espace entre les lignes d'objectifs dans une quête."
L["Spacing below header (px)"]                          = "Espacement sous l'en-tête (px)"
L["Vertical gap between the objectives bar and the quest list."] = "Espace entre la barre d'objectifs et la liste de quêtes."
L["Reset spacing"]                                      = "Réinitialiser l'espacement"

-- =====================================================================
-- OptionsData.lua Display — Other
-- =====================================================================
L["Show quest level"]                                   = "Afficher le niveau de quête"
L["Show quest level next to title."]                    = "Affiche le niveau de quête à côté du titre."
L["Dim non-focused quests"]                             = "Atténuer les quêtes non actives"
L["Slightly dim title, zone, objectives, and section headers that are not focused."] = "Atténue légèrement les titres, zones, objectifs et en-têtes non actifs."

-- =====================================================================
-- Features — Rare bosses
-- =====================================================================
L["Show rare bosses"]                                   = "Afficher les boss rares"
L["Show rare boss vignettes in the list."]              = "Affiche les boss rares dans la liste."
L["Rare added sound"]                                   = "Son d'ajout de rare"
L["Play a sound when a rare is added."]                 = "Joue un son quand un rare est ajouté."

-- =====================================================================
-- OptionsData.lua Features — World quests
-- =====================================================================
L["Show in-zone world quests"]                          = "Afficher les quêtes mondiales en zone"
L["Auto-add world quests in your current zone. When off, only quests you've tracked or world quests you're in close proximity to appear (Blizzard default)."] = "Ajoute automatiquement les quêtes mondiales de votre zone. Désactivé : seules les quêtes suivies ou proches sont affichées (par défaut Blizzard)."

-- =====================================================================
-- OptionsData.lua Features — Floating quest item
-- =====================================================================
L["Show floating quest item"]                           = "Afficher l'objet de quête flottant"
L["Show quick-use button for the focused quest's usable item."] = "Affiche le bouton d'utilisation rapide pour l'objet de la quête active."
L["Lock floating quest item position"]                  = "Verrouiller la position de l'objet flottant"
L["Prevent dragging the floating quest item button."]   = "Empêche de déplacer le bouton d'objet de quête flottant."
L["Floating quest item source"]                         = "Source de l'objet flottant"
L["Which quest's item to show: super-tracked first, or current zone first."] = "Quel objet afficher : quête suivie en priorité ou zone actuelle en priorité."
L["Super-tracked, then first"]                          = "Quête suivie en priorité"
L["Current zone first"]                                 = "Zone actuelle en priorité"

-- =====================================================================
-- OptionsData.lua Features — Mythic+
-- =====================================================================
L["Show Mythic+ block"]                                 = "Afficher le bloc Mythique+"
L["Show timer, completion %, and affixes in Mythic+ dungeons."] = "Affiche le timer, le % de complétion et les affixes en Mythique+."
L["M+ block position"]                                  = "Position du bloc M+"
L["Position of the Mythic+ block relative to the quest list."] = "Position du bloc Mythique+ par rapport à la liste de quêtes."
L["Show affix icons"]                                    = "Afficher les icônes d'affixes"
L["Show affix icons next to modifier names in the M+ block."] = "Affiche les icônes d'affixes à côté des noms dans le bloc M+."
L["Show affix descriptions in tooltip"]                  = "Descriptions d'affixes dans l'infobulle"
L["Show affix descriptions when hovering over the M+ block."] = "Affiche les descriptions d'affixes au survol du bloc M+."
L["M+ completed boss display"]                         = "Affichage des boss M+ terminés"
L["How to show defeated bosses: checkmark icon or green color."] = "Affichage des boss vaincus : icône coche ou couleur verte."
L["Checkmark"]                                          = "Coche"
L["Green color"]                                        = "Vert"

-- =====================================================================
-- OptionsData.lua Features — Achievements
-- =====================================================================
L["Show achievements"]                                  = "Afficher les hauts faits"
L["Show tracked achievements in the list."]             = "Affiche les hauts faits suivis dans la liste."
L["Show completed achievements"]                        = "Afficher les hauts faits terminés"
L["Include completed achievements in the tracker. When off, only in-progress tracked achievements are shown."] = "Inclut les hauts faits terminés. Désactivé : seuls les hauts faits en cours sont affichés."
L["Show achievement icons"]                             = "Afficher les icônes de hauts faits"
L["Show each achievement's icon next to the title. Requires 'Show quest type icons' in Display."] = "Affiche l'icône de chaque haut fait à côté du titre. Nécessite « Afficher les icônes de type de quête » dans Affichage."
L["Only show missing requirements"]                     = "Afficher uniquement les critères manquants"
L["Show only criteria you haven't completed for each tracked achievement. When off, all criteria are shown."] = "Affiche uniquement les critères non terminés pour chaque haut fait suivi. Désactivé : tous les critères sont affichés."

-- =====================================================================
-- OptionsData.lua Features — Endeavors
-- =====================================================================
L["Show endeavors"]                                     = "Afficher les défis"
L["Show tracked Endeavors (Player Housing) in the list."] = "Affiche les défis suivis (logement) dans la liste."
L["Show completed endeavors"]                           = "Afficher les défis terminés"
L["Include completed Endeavors in the tracker. When off, only in-progress tracked Endeavors are shown."] = "Inclut les défis terminés. Désactivé : seuls les défis en cours sont affichés."

-- =====================================================================
-- OptionsData.lua Features — Decor
-- =====================================================================
L["Show decor"]                                         = "Afficher les décorations"
L["Show tracked housing decor in the list."]            = "Affiche les décorations suivies dans la liste."
L["Show decor icons"]                                   = "Afficher les icônes de décorations"
L["Show each decor item's icon next to the title. Requires 'Show quest type icons' in Display."] = "Affiche l'icône de chaque décoration à côté du titre. Nécessite « Afficher les icônes de type de quête » dans Affichage."

-- =====================================================================
-- OptionsData.lua Features — Scenario & Delve
-- =====================================================================
L["Show scenario events"]                               = "Afficher les événements de scénario"
L["Show active scenario and Delve activities. Delves appear in DELVES; other scenarios in SCENARIO EVENTS."] = "Affiche les scénarios et explorations actifs. Les explorations dans EXPLORATIONS ; les autres dans ÉVÉNEMENTS DE SCÉNARIO."
L["Hide other categories in Delve or Dungeon"]          = "Masquer les autres catégories en exploration ou donjon"
L["In Delves or party dungeons, show only the Delve/Dungeon section."] = "En exploration ou donjon de groupe, affiche uniquement la section correspondante."
L["Use delve name as section header"]                    = "Utiliser le nom d'exploration comme en-tête"
L["When in a Delve, show the delve name, tier, and affixes as the section header instead of a separate banner. Disable to show the Delve block above the list."] = "En exploration : affiche le nom, le palier et les affixes dans l'en-tête. Désactivé : affiche le bloc au-dessus de la liste."
L["Show affix names in Delves"]                         = "Afficher les affixes en exploration"
L["Show season affix names on the first Delve entry. Requires Blizzard's objective tracker widgets to be populated; may not show when using a full tracker replacement."] = "Affiche les noms d'affixes sur la première entrée. Nécessite les widgets Blizzard ; peut ne pas s'afficher avec un remplacement complet."
L["Cinematic scenario bar"]                             = "Barre de scénario cinématique"
L["Show timer and progress bar for scenario entries."]  = "Affiche le timer et la barre de progression pour les scénarios."
L["Scenario bar opacity"]                               = "Opacité de la barre de scénario"
L["Opacity of scenario timer/progress bar (0–1)."]      = "Opacité du timer/barre de progression (0–1)."
L["Scenario bar height"]                                = "Hauteur de la barre de scénario"
L["Height of scenario progress bar (4–8 px)."]          = "Hauteur de la barre de progression (4–8 px)."

-- =====================================================================
-- OptionsData.lua Typography — Font
-- =====================================================================
L["Font family."]                                       = "Police."
L["Header size"]                                        = "Taille de l'en-tête"
L["Header font size."]                                  = "Taille de police de l'en-tête."
L["Title size"]                                         = "Taille du titre"
L["Quest title font size."]                             = "Taille de police des titres de quête."
L["Objective size"]                                     = "Taille des objectifs"
L["Objective text font size."]                          = "Taille de police du texte des objectifs."
L["Zone size"]                                          = "Taille des zones"
L["Zone label font size."]                              = "Taille de police des libellés de zone."
L["Section size"]                                       = "Taille des sections"
L["Section header font size."]                          = "Taille de police des en-têtes de section."
L["Outline"]                                            = "Contour"
L["Font outline style."]                                = "Style de contour de police."

-- =====================================================================
-- OptionsData.lua Typography — Text case
-- =====================================================================
L["Header text case"]                                   = "Casse de l'en-tête"
L["Display case for header."]                           = "Casse d'affichage pour l'en-tête."
L["Section header case"]                                = "Casse des en-têtes de section"
L["Display case for category labels."]                  = "Casse d'affichage pour les libellés de catégorie."
L["Quest title case"]                                   = "Casse des titres de quête"
L["Display case for quest titles."]                     = "Casse d'affichage pour les titres de quête."

-- =====================================================================
-- OptionsData.lua Typography — Shadow
-- =====================================================================
L["Show text shadow"]                                   = "Afficher l'ombre du texte"
L["Enable drop shadow on text."]                        = "Active l'ombre portée sur le texte."
L["Shadow X"]                                           = "Ombre X"
L["Horizontal shadow offset."]                          = "Décalage horizontal de l'ombre."
L["Shadow Y"]                                           = "Ombre Y"
L["Vertical shadow offset."]                            = "Décalage vertical de l'ombre."
L["Shadow alpha"]                                       = "Opacité de l'ombre"
L["Shadow opacity (0–1)."]                              = "Opacité de l'ombre (0–1)."

-- =====================================================================
-- OptionsData.lua Typography — Mythic+ Typography
-- =====================================================================
L["Mythic+ Typography"]                                  = "Typographie Mythique+"
L["Dungeon name size"]                                   = "Taille du nom de donjon"
L["Font size for dungeon name (8–32 px)."]              = "Taille de police du nom de donjon (8–32 px)."
L["Dungeon name color"]                                  = "Couleur du nom de donjon"
L["Text color for dungeon name."]                        = "Couleur du texte du nom de donjon."
L["Timer size"]                                         = "Taille du timer"
L["Font size for timer (8–32 px)."]                     = "Taille de police du timer (8–32 px)."
L["Timer color"]                                        = "Couleur du timer"
L["Text color for timer (in time)."]                    = "Couleur du timer (dans le temps)."
L["Timer overtime color"]                               = "Couleur du timer en dépassement"
L["Text color for timer when over the time limit."]      = "Couleur du timer en dépassement de temps."
L["Progress size"]                                      = "Taille de la progression"
L["Font size for enemy forces (8–32 px)."]               = "Taille de police des forces ennemies (8–32 px)."
L["Progress color"]                                     = "Couleur de la progression"
L["Text color for enemy forces."]                        = "Couleur du texte des forces ennemies."
L["Bar fill color"]                                     = "Couleur de remplissage de la barre"
L["Progress bar fill color (in progress)."]             = "Couleur de remplissage de la barre (en cours)."
L["Bar complete color"]                                 = "Couleur de la barre terminée"
L["Progress bar fill color when enemy forces are at 100%."] = "Couleur de remplissage quand les forces ennemies sont à 100%."
L["Affix size"]                                         = "Taille des affixes"
L["Font size for affixes (8–32 px)."]                   = "Taille de police des affixes (8–32 px)."
L["Affix color"]                                        = "Couleur des affixes"
L["Text color for affixes."]                             = "Couleur du texte des affixes."
L["Boss size"]                                          = "Taille des noms de boss"
L["Font size for boss names (8–32 px)."]                = "Taille de police des noms de boss (8–32 px)."
L["Boss color"]                                         = "Couleur des noms de boss"
L["Text color for boss names."]                          = "Couleur du texte des noms de boss."
L["Reset Mythic+ typography"]                           = "Réinitialiser la typographie M+"

-- =====================================================================
-- OptionsData.lua Appearance
-- =====================================================================
L["Backdrop opacity"]                                   = "Opacité du fond"
L["Panel background opacity (0–1)."]                    = "Opacité du fond du panneau (0–1)."
L["Show border"]                                        = "Afficher la bordure"
L["Show border around the tracker."]                    = "Affiche le cadre autour du suivi."
L["Highlight alpha"]                                    = "Opacité du surlignage"
L["Opacity of focused quest highlight (0–1)."]          = "Opacité du surlignage de la quête active (0–1)."
L["Bar width"]                                          = "Largeur de la barre"
L["Width of bar-style highlights (2–6 px)."]            = "Largeur des surlignages en barre (2–6 px)."

-- =====================================================================
-- OptionsData.lua Organization
-- =====================================================================
L["Focus category order"]                               = "Ordre des catégories Focus"
L["Drag to reorder categories. DELVES and SCENARIO EVENTS stay first."] = "Glissez pour réordonner. EXPLORATIONS et ÉVÉNEMENTS DE SCÉNARIO restent en premier."
L["Focus sort mode"]                                    = "Mode de tri Focus"
L["Order of entries within each category."]             = "Ordre des entrées dans chaque catégorie."
L["Auto-track accepted quests"]                         = "Suivi auto des quêtes acceptées"
L["When you accept a quest (quest log only, not world quests), add it to the tracker automatically."] = "Ajoute automatiquement les quêtes acceptées au suivi (journal uniquement, pas les quêtes mondiales)."
L["Require Ctrl for focus & remove"]                    = "Ctrl requis pour suivre / retirer"
L["Require Ctrl for focus/add (Left) and unfocus/untrack (Right) to prevent misclicks."] = "Exige Ctrl pour suivre (clic gauche) et retirer (clic droit) afin d'éviter les clics accidentels."
L["Animations"]                                         = "Animations"
L["Enable slide and fade for quests."]                  = "Active le glissement et le fondu pour les quêtes."
L["Objective progress flash"]                           = "Flash de progression d'objectif"
L["Show flash when an objective completes."]            = "Affiche un flash quand un objectif est terminé."
L["Flash intensity"]                                   = "Intensité du flash"
L["How noticeable the objective-complete flash is."]    = "Intensité du flash à la complétion d'un objectif."
L["Flash color"]                                        = "Couleur du flash"
L["Color of the objective-complete flash."]             = "Couleur du flash à la complétion d'un objectif."
L["Subtle"]                                             = "Subtil"
L["Medium"]                                             = "Moyen"
L["Strong"]                                             = "Fort"
L["Require Ctrl for click to complete"]                 = "Ctrl requis pour cliquer et terminer"
L["When on, requires Ctrl+Left-click to complete auto-complete quests. When off, plain Left-click completes them (Blizzard default). Only affects quests that can be completed by click (no NPC turn-in needed)."] = "Activé : Ctrl+clic gauche pour terminer. Désactivé : simple clic gauche (par défaut Blizzard). Affecte uniquement les quêtes terminables par clic."
L["Suppress untracked until reload"]                     = "Masquer les non suivies jusqu'au rechargement"
L["When on, right-click untrack on world quests and in-zone weeklies/dailies hides them until you reload or start a new session. When off, they reappear when you return to the zone."] = "Activé : les quêtes non suivies restent masquées jusqu'au rechargement. Désactivé : elles réapparaissent à votre retour en zone."
L["Permanently suppress untracked quests"]               = "Masquer définitivement les quêtes non suivies"
L["When on, right-click untracked world quests and in-zone weeklies/dailies are hidden permanently (persists across reloads). Takes priority over 'Suppress until reload'. Accepting a suppressed quest removes it from the blacklist."] = "Activé : les quêtes non suivies restent masquées définitivement. Prioritaire sur « Masquer jusqu'au rechargement ». Accepter une quête masquée la retire de la liste."

-- =====================================================================
-- OptionsData.lua Blacklist
-- =====================================================================
L["Blacklisted quests"]                                  = "Quêtes sur liste noire"
L["Permanently suppressed quests"]                       = "Quêtes masquées définitivement"
L["Right-click untrack quests with 'Permanently suppress untracked quests' enabled to add them here."] = "Clic droit pour retirer les quêtes avec « Masquer définitivement » activé afin de les ajouter ici."

-- =====================================================================
-- OptionsData.lua Presence
-- =====================================================================
L["Show quest type icons"]                              = "Afficher les icônes de type de quête"
L["Show quest type icon in the Focus tracker (quest accept/complete, world quest, quest update)."] = "Affiche dans le suivi : quête acceptée/terminée, quête mondiale, mise à jour."
L["Show quest type icons on toasts"]                    = "Icônes de type sur les notifications"
L["Show quest type icon on Presence toasts (quest accept/complete, world quest, quest update)."] = "Affiche l'icône de type sur les notifications : quête acceptée/terminée, quête mondiale, mise à jour."
L["Toast icon size"]                                    = "Taille des icônes de notification"
L["Quest icon size on Presence toasts (16–36 px). Default 24."] = "Taille des icônes de quête sur les notifications (16–36 px). Par défaut 24."
L["Show discovery line"]                                = "Afficher la ligne de découverte"
L["Show 'Discovered' under zone/subzone when entering a new area."] = "Affiche « Découverte » sous zone/sous-zone à l'entrée d'une nouvelle zone."
L["Frame vertical position"]                            = "Position verticale du cadre"
L["Vertical offset of the Presence frame from center (-300 to 0)."] = "Décalage vertical du cadre depuis le centre (-300 à 0)."
L["Frame scale"]                                        = "Échelle du cadre"
L["Scale of the Presence frame (0.5–1.5)."]             = "Échelle du cadre Presence (0.5–1.5)."
L["Boss emote color"]                                   = "Couleur des émojis de boss"
L["Color of raid and dungeon boss emote text."]          = "Couleur du texte des émojis de boss en raid et donjon."
L["Discovery line color"]                               = "Couleur de la ligne de découverte"
L["Color of the 'Discovered' line under zone text."]     = "Couleur de la ligne « Découverte » sous le texte de zone."
L["Notification types"]                                 = "Types de notifications"
L["Show zone changes"]                                  = "Afficher les changements de zone"
L["Show zone and subzone change notifications."]        = "Affiche les notifications de changement de zone et sous-zone."
L["Show level up"]                                      = "Afficher la montée de niveau"
L["Show level-up notification."]                        = "Affiche la notification de montée de niveau."
L["Show boss emotes"]                                   = "Afficher les émojis de boss"
L["Show raid and dungeon boss emote notifications."]    = "Affiche les notifications d'émojis de boss en raid et donjon."
L["Show achievements"]                                  = "Afficher les hauts faits"
L["Show achievement earned notifications."]            = "Affiche les notifications de hauts faits obtenus."
L["Show quest events"]                                  = "Afficher les événements de quête"
L["Show quest accept, complete, and progress notifications."] = "Affiche les notifications de quête acceptée, terminée et en progression."
L["Animation"]                                          = "Animation"
L["Enable animations"]                                  = "Activer les animations"
L["Enable entrance and exit animations for Presence notifications."] = "Active les animations d'entrée et de sortie des notifications."
L["Entrance duration"]                                  = "Durée d'entrée"
L["Duration of the entrance animation in seconds (0.2–1.5)."] = "Durée de l'animation d'entrée en secondes (0.2–1.5)."
L["Exit duration"]                                      = "Durée de sortie"
L["Duration of the exit animation in seconds (0.2–1.5)."] = "Durée de l'animation de sortie en secondes (0.2–1.5)."
L["Hold duration scale"]                                = "Facteur de durée d'affichage"
L["Multiplier for how long each notification stays on screen (0.5–2)."] = "Multiplicateur de la durée d'affichage des notifications (0.5–2)."
L["Typography"]                                         = "Typographie"
L["Main title size"]                                    = "Taille du titre principal"
L["Font size for the main title (24–72 px)."]            = "Taille de police du titre principal (24–72 px)."
L["Subtitle size"]                                      = "Taille du sous-titre"
L["Font size for the subtitle (12–40 px)."]             = "Taille de police du sous-titre (12–40 px)."

-- =====================================================================
-- OptionsData.lua Dropdown options — Outline
-- =====================================================================
L["None"]                                               = "Aucun"
L["Thick Outline"]                                      = "Contour épais"

-- =====================================================================
-- OptionsData.lua Dropdown options — Highlight style
-- =====================================================================
L["Bar (left edge)"]                                    = "Barre (bord gauche)"
L["Bar (right edge)"]                                   = "Barre (bord droit)"
L["Bar (top edge)"]                                     = "Barre (bord supérieur)"
L["Bar (bottom edge)"]                                  = "Barre (bord inférieur)"
L["Outline only"]                                       = "Contour uniquement"
L["Soft glow"]                                          = "Lueur douce"
L["Dual edge bars"]                                     = "Barres doubles"
L["Pill left accent"]                                   = "Accent pilule gauche"

-- =====================================================================
-- OptionsData.lua Dropdown options — M+ position
-- =====================================================================
L["Top"]                                                = "Haut"
L["Bottom"]                                             = "Bas"

-- =====================================================================
-- OptionsData.lua Dropdown options — Text case
-- =====================================================================
L["Lower Case"]                                         = "Minuscules"
L["Upper Case"]                                         = "Majuscules"
L["Proper"]                                             = "Première lettre en majuscule"

-- =====================================================================
-- OptionsData.lua Dropdown options — Header count format
-- =====================================================================
L["Tracked / in log"]                                   = "Suivies / journal"
L["In log / max slots"]                                 = "Journal / max"

-- =====================================================================
-- OptionsData.lua Dropdown options — Sort mode
-- =====================================================================
L["Alphabetical"]                                       = "Alphabétique"
L["Quest Type"]                                         = "Type de quête"
L["Quest Level"]                                        = "Niveau de quête"

-- =====================================================================
-- OptionsData.lua Misc
-- =====================================================================
L["Custom"]                                             = "Personnalisé"
L["Order"]                                              = "Ordre"

-- =====================================================================
-- Tracker section labels (SECTION_LABELS)
-- =====================================================================
L["DUNGEON"]           = "DONJON"
L["DELVES"]            = "EXPLORATIONS"
L["SCENARIO EVENTS"]   = "ÉVÉNEMENTS DE SCÉNARIO"
L["AVAILABLE IN ZONE"] = "DISPONIBLE EN ZONE"
L["CURRENT ZONE"]      = "ZONE ACTUELLE"
L["CAMPAIGN"]          = "CAMPAGNE"
L["IMPORTANT"]         = "IMPORTANT"
L["LEGENDARY"]         = "LÉGENDAIRE"
L["WORLD QUESTS"]      = "QUÊTES MONDIALES"
L["WEEKLY QUESTS"]     = "QUÊTES HEBDOMADAIRES"
L["DAILY QUESTS"]      = "QUÊTES JOURNALIÈRES"
L["RARE BOSSES"]       = "BOSS RARES"
L["ACHIEVEMENTS"]      = "HAUTS FAITS"
L["ENDEAVORS"]         = "DÉFIS"
L["DECOR"]             = "DÉCORATION"
L["QUESTS"]            = "QUÊTES"
L["READY TO TURN IN"]  = "PRÊT À RENDRE"

-- =====================================================================
-- Core.lua, FocusLayout.lua, PresenceCore.lua, FocusUnacceptedPopup.lua
-- =====================================================================
L["OBJECTIVES"]                                                                                    = "OBJECTIFS"
L["Options"]                                                                                       = "Options"
L["Discovered"]                                                                                    = "Découverte"
L["Refresh"]                                                                                       = "Actualiser"
L["Best-effort only. Some unaccepted quests are not exposed until you interact with NPCs or meet phasing conditions."] = "Recherche approximative. Certaines quêtes non acceptées ne sont pas visibles avant d'interagir avec des PNJ ou de remplir des conditions de phase."
L["Unaccepted Quests - %s (map %s) - %d match(es)"]                                                  = "Quêtes non acceptées - %s (carte %s) - %d correspondance(s)"
