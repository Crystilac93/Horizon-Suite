if GetLocale() ~= "koKR" then return end

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
L["Focus"]                                                          = "퀘스트 목록 설정"
L["Presence"]                                                       = "진행 알림 설정"
L["Other"]                                                          = "기타"

-- =====================================================================
-- OptionsPanel.lua — Section headers
-- =====================================================================
L["Quest types"]                                                    = "퀘스트 유형"
L["Element overrides"]                                              = "개별 요소 색상"
L["Per category"]                                                   = "유형별 색상"
L["Grouping Overrides"]                                             = "그룹 우선 색상"
L["Other colors"]                                                   = "기타 색상"

-- =====================================================================
-- OptionsPanel.lua — Color row labels (collapsible group sub-rows)
-- =====================================================================
L["Section"]                                                        = "구역"
L["Title"]                                                          = "제목"
L["Zone"]                                                           = "지역"
L["Objective"]                                                      = "목표"

-- =====================================================================
-- OptionsPanel.lua — Toggle switch labels & tooltips
-- =====================================================================
L["Ready to Turn In overrides base colours"]                        = "완료 퀘스트 색상을 우선 적용"
L["Ready to Turn In uses its colours for quests in that section."]  = "보고 가능한 퀘스트가 있으면 해당 구역에 완료 색상을 우선 적용합니다."
L["Current Zone overrides base colours"]                            = "현재 지역 색상을 우선 적용"
L["Current Zone uses its colours for quests in that section."]      = "현재 지역에 해당하는 퀘스트가 있으면 해당 구역에 지역 색상을 우선 적용합니다."
L["Use distinct color for completed objectives"]                     = "완료된 목표에 다른 색상 사용"
L["When on, completed objectives (e.g. 1/1) use the color below; when off, they use the same color as incomplete objectives."] = "활성화하면 완료된 목표(예: 1/1)에 아래 색상을 사용하고, 비활성화하면 미완료 목표와 같은 색상을 사용합니다."
L["Completed objective"]                                           = "완료된 목표"

-- =====================================================================
-- OptionsPanel.lua — Button labels
-- =====================================================================
L["Reset"]                                                          = "초기화"
L["Reset quest types"]                                              = "퀘스트 유형 초기화"
L["Reset overrides"]                                                = "개별 요소 초기화"
L["Reset to defaults"]                                              = "기본값으로 초기화"
L["Reset to default"]                                               = "기본값으로 초기화"

-- =====================================================================
-- OptionsPanel.lua — Search bar placeholder
-- =====================================================================
L["Search settings..."]                                             = "설정 검색..."

-- =====================================================================
-- OptionsPanel.lua — Resize handle tooltip
-- =====================================================================
L["Drag to resize"]                                                 = "드래그하여 크기 조절"

-- =====================================================================
-- OptionsData.lua Category names (sidebar)
-- =====================================================================
L["Modules"]                                            = "모듈"
L["Layout"]                                             = "레이아웃"
L["Visibility"]                                         = "표시 조건"
L["Display"]                                            = "표시"
L["Features"]                                           = "기능"
L["Typography"]                                         = "글꼴"
L["Appearance"]                                         = "외형"
L["Colors"]                                             = "색상"
L["Organization"]                                       = "정렬"

-- =====================================================================
-- OptionsData.lua Section headers
-- =====================================================================
L["Panel behaviour"]                                    = "패널 동작"
L["Dimensions"]                                         = "크기"
L["Instance"]                                           = "인스턴스"
L["Combat"]                                             = "전투"
L["Filtering"]                                          = "필터"
L["Header"]                                             = "헤더"
L["List"]                                               = "목록"
L["Spacing"]                                            = "간격"
L["Rare bosses"]                                        = "희귀 보스"
L["World quests"]                                       = "월드 퀘스트"
L["Floating quest item"]                                = "퀘스트 아이템 버튼"
L["Mythic+"]                                            = "쐐기돌"
L["Achievements"]                                       = "업적"
L["Endeavors"]                                          = "활동 과제"
L["Decor"]                                              = "장식"
L["Scenario & Delve"]                                   = "시나리오 및 심층 탐사"
L["Font"]                                               = "글꼴"
L["Text case"]                                          = "대소문자"
L["Shadow"]                                             = "그림자"
L["Panel"]                                              = "패널"
L["Highlight"]                                          = "강조"
L["Color matrix"]                                       = "색상표"
L["Focus order"]                                        = "Focus 순서"
L["Sort"]                                               = "정렬"
L["Behaviour"]                                          = "동작"

-- =====================================================================
-- OptionsData.lua Modules
-- =====================================================================
L["Enable Focus module"]                                = "Focus 모듈 활성화"
L["Show the objective tracker for quests, world quests, rares, achievements, and scenarios."] = "퀘스트, 월드 퀘스트, 희귀 몹, 업적, 시나리오를 추적하는 목표 추적기를 표시합니다."
L["Enable Presence module"]                             = "Presence 모듈 활성화"
L["Cinematic zone text and notifications (zone changes, level up, boss emotes, achievements, quest updates)."] = "시네마틱 지역 텍스트 및 알림 (지역 이동, 레벨 업, 보스 감정 표현, 업적, 퀘스트 갱신)."

-- =====================================================================
-- OptionsData.lua Layout
-- =====================================================================
L["Lock position"]                                      = "위치 잠금"
L["Prevent dragging the tracker."]                      = "추적기를 드래그할 수 없게 합니다."
L["Grow upward"]                                        = "위로 확장"
L["Anchor at bottom so the list grows upward."]         = "하단 기준으로 목록이 위쪽으로 확장됩니다."
L["Start collapsed"]                                    = "접힌 상태로 시작"
L["Start with only the header shown until you expand."] = "펼치기 전까지 헤더만 표시합니다."
L["Panel width"]                                        = "패널 너비"
L["Tracker width in pixels."]                           = "추적기 너비 (픽셀)."
L["Max content height"]                                 = "최대 콘텐츠 높이"
L["Max height of the scrollable list (pixels)."]        = "스크롤 목록의 최대 높이 (픽셀)."

-- =====================================================================
-- OptionsData.lua Visibility
-- =====================================================================
L["Always show M+ block"]                                           = "쐐기돌 블록 항상 표시"
L["Show the M+ block whenever an active keystone is running"]       = "활성 쐐기돌 실행 중에는 쐐기돌 블록을 항상 표시합니다."
L["Show in dungeon"]                                    = "던전에서 표시"
L["Show tracker in party dungeons."]                    = "파티 던전에서 추적기를 표시합니다."
L["Show in raid"]                                       = "공격대에서 표시"
L["Show tracker in raids."]                             = "공격대에서 추적기를 표시합니다."
L["Show in battleground"]                               = "전장에서 표시"
L["Show tracker in battlegrounds."]                     = "전장에서 추적기를 표시합니다."
L["Show in arena"]                                      = "투기장에서 표시"
L["Show tracker in arenas."]                            = "투기장에서 추적기를 표시합니다."
L["Hide in combat"]                                     = "전투 중 숨기기"
L["Hide tracker and floating quest item in combat."]    = "전투 중 추적기와 퀘스트 아이템 버튼을 숨깁니다."
L["Only show quests in current zone"]                   = "현재 지역 퀘스트만 표시"
L["Hide quests outside your current zone."]             = "현재 지역 밖의 퀘스트를 숨깁니다."

-- =====================================================================
-- OptionsData.lua Display — Header
-- =====================================================================
L["Show quest count"]                                   = "퀘스트 수 표시"
L["Show quest count in header."]                        = "헤더에 퀘스트 수를 표시합니다."
L["Header count format"]                                = "헤더 수 표시 형식"
L["Tracked/in-log or in-log/max-slots. Tracked excludes world/live-in-zone quests."] = "추적 중/퀘스트 목록 또는 퀘스트 목록/최대 슬롯. 추적 수에는 월드 퀘스트가 포함되지 않습니다."
L["Show header divider"]                                = "헤더 구분선 표시"
L["Show the line below the header."]                    = "헤더 아래 구분선을 표시합니다."
L["Super-minimal mode"]                                 = "초간결 모드"
L["Hide header for a pure text list."]                  = "헤더를 숨기고 텍스트 목록만 표시합니다."
L["Show options button"]                               = "옵션 버튼 표시"
L["Show the Options button in the tracker header."]     = "추적기 헤더에 옵션 버튼을 표시합니다."
L["Header color"]                                       = "헤더 색상"
L["Color of the OBJECTIVES header text."]               = "목표 헤더 텍스트의 색상."
L["Header height"]                                      = "헤더 높이"
L["Height of the header bar in pixels (18–48)."]        = "헤더 바 높이 (픽셀, 18–48)."

-- =====================================================================
-- OptionsData.lua Display — List
-- =====================================================================
L["Show section headers"]                               = "구역 헤더 표시"
L["Show category labels above each group."]             = "각 그룹 위에 유형 라벨을 표시합니다."
L["Show category headers when collapsed"]               = "접힌 상태에서 구역 헤더 표시"
L["Keep section headers visible when collapsed; click to expand a category."] = "접힌 상태에서도 구역 헤더를 표시합니다. 클릭하면 해당 유형을 펼칩니다."
L["Show Nearby (Current Zone) group"]                   = "근처(현재 지역) 그룹 표시"
L["Show in-zone quests in a dedicated Current Zone section. When off, they appear in their normal category."] = "현재 지역 퀘스트를 전용 구역으로 표시합니다. 끄면 기존 유형에 그대로 표시됩니다."
L["Show zone labels"]                                   = "지역명 표시"
L["Show zone name under each quest title."]             = "각 퀘스트 제목 아래에 지역명을 표시합니다."
L["Active quest highlight"]                             = "퀘스트 강조"
L["How the focused quest is highlighted."]              = "퀘스트의 강조 방식."
L["Show quest item buttons"]                            = "퀘스트 아이템 버튼 표시"
L["Show usable quest item button next to each quest."]  = "각 퀘스트 옆에 사용 가능한 아이템 버튼을 표시합니다."
L["Show objective numbers"]                             = "목표 번호 표시"
L["Prefix objectives with 1., 2., 3."]                  = "목표 앞에 1., 2., 3. 번호를 붙입니다."
L["Show completed count"]                               = "완료 수 표시"
L["Show X/Y progress in quest title."]                  = "퀘스트 제목에 X/Y 진행도를 표시합니다."
L["Use tick for completed objectives"]                  = "완료된 목표에 체크 표시 사용"
L["When on, completed objectives show a checkmark (✓) instead of green color."] = "활성화하면 완료된 목표에 초록색 대신 체크 표시(✓)가 나타납니다."
L["Show entry numbers"]                                 = "항목 번호 표시"
L["Prefix quest titles with 1., 2., 3. within each category."] = "각 유형 내에서 퀘스트 제목 앞에 1., 2., 3. 번호를 붙입니다."
L["Completed objectives"]                               = "완료된 목표"
L["For multi-objective quests, how to display objectives you've completed (e.g. 1/1)."] = "다중 목표 퀘스트에서 완료된 목표(예: 1/1) 표시 방식."
L["Show all"]                                           = "모두 표시"
L["Fade completed"]                                     = "완료 시 흐리게"
L["Hide completed"]                                     = "완료 시 숨기기"
L["Show '**' in-zone suffix"]                           = "지역 내 '**' 접미사 표시"
L["Append ** to world quests and weeklies/dailies that are not yet in your quest log (in-zone only)."] = "퀘스트 목록에 없는 월드 퀘스트/주간·일일 퀘스트에 ** 접미사를 붙입니다 (해당 지역 내에서만)."

-- =====================================================================
-- OptionsData.lua Display — Spacing
-- =====================================================================
L["Compact mode"]                                       = "간결 모드"
L["Preset: sets entry and objective spacing to 4 and 1 px."] = "사전 설정: 퀘스트 간격 4px, 목표 간격 1px로 설정합니다."
L["Spacing between quest entries (px)"]                 = "퀘스트 항목 간격 (px)"
L["Vertical gap between quest entries."]                = "퀘스트 항목 사이의 세로 간격."
L["Spacing before category header (px)"]                = "구역 헤더 위 간격 (px)"
L["Gap between last entry of a group and the next category label."] = "이전 그룹의 마지막 항목과 다음 구역 라벨 사이의 간격."
L["Spacing after category header (px)"]                 = "구역 헤더 아래 간격 (px)"
L["Gap between category label and first quest entry below it."] = "구역 라벨과 첫 번째 퀘스트 항목 사이의 간격."
L["Spacing between objectives (px)"]                    = "목표 간격 (px)"
L["Vertical gap between objective lines within a quest."] = "퀘스트 내 목표 줄 사이의 세로 간격."
L["Spacing below header (px)"]                          = "헤더 아래 간격 (px)"
L["Vertical gap between the objectives bar and the quest list."] = "목표 바와 퀘스트 목록 사이의 세로 간격."
L["Reset spacing"]                                      = "간격 초기화"

-- =====================================================================
-- OptionsData.lua Display — Other
-- =====================================================================
L["Show quest level"]                                   = "퀘스트 레벨 표시"
L["Show quest level next to title."]                    = "제목 옆에 퀘스트 레벨을 표시합니다."
L["Dim non-focused quests"]                             = "비활성 퀘스트 흐리게"
L["Slightly dim title, zone, objectives, and section headers that are not focused."] = "포커스되지 않은 퀘스트의 제목, 지역, 목표, 구역 헤더를 약간 흐리게 표시합니다."

-- =====================================================================
-- Features — Rare bosses
-- =====================================================================
L["Show rare bosses"]                                   = "희귀 보스 표시"
L["Show rare boss vignettes in the list."]              = "목록에 희귀 보스를 표시합니다."
L["Rare added sound"]                                   = "희귀 몹 등장 효과음"
L["Play a sound when a rare is added."]                 = "희귀 몹이 추가되면 효과음을 재생합니다."

-- =====================================================================
-- OptionsData.lua Features — World quests
-- =====================================================================
L["Show in-zone world quests"]                          = "현재 지역 월드 퀘스트 표시"
L["Auto-add world quests in your current zone. When off, only quests you've tracked or world quests you're in close proximity to appear (Blizzard default)."] = "현재 지역의 월드 퀘스트를 자동으로 표시합니다. 끄면 추적 목록에 있거나 퀘스트 지역에 가까이 있는 월드 퀘스트만 표시됩니다 (블리자드 기본값)."

-- =====================================================================
-- OptionsData.lua Features — Floating quest item
-- =====================================================================
L["Show floating quest item"]                           = "퀘스트 아이템 버튼 표시"
L["Show quick-use button for the focused quest's usable item."] = "포커스된 퀘스트의 사용 가능한 아이템을 빠른 사용 버튼으로 표시합니다."
L["Lock floating quest item position"]                  = "퀘스트 아이템 버튼 위치 잠금"
L["Prevent dragging the floating quest item button."]   = "퀘스트 아이템 버튼을 드래그할 수 없게 합니다."
L["Floating quest item source"]                         = "퀘스트 아이템 버튼 소스"
L["Which quest's item to show: super-tracked first, or current zone first."] = "표시할 퀘스트 아이템: 초점 퀘스트 우선 또는 현재 지역 우선."
L["Super-tracked, then first"]                          = "초점 퀘스트 우선"
L["Current zone first"]                                 = "현재 지역 우선"

-- =====================================================================
-- OptionsData.lua Features — Mythic+
-- =====================================================================
L["Show Mythic+ block"]                                 = "쐐기돌 블록 표시"
L["Show timer, completion %, and affixes in Mythic+ dungeons."] = "쐐기돌 던전에서 타이머, 완료율, 쐐기돌 속성을 표시합니다."
L["M+ block position"]                                  = "쐐기돌 블록 위치"
L["Position of the Mythic+ block relative to the quest list."] = "퀘스트 목록에 대한 쐐기돌 블록의 위치."
L["Show affix icons"]                                    = "시즌 효과 아이콘 표시"
L["Show affix icons next to modifier names in the M+ block."] = "쐐기돌 블록의 시즌 효과 이름 옆에 아이콘을 표시합니다."
L["Show affix descriptions in tooltip"]                  = "툴팁에 시즌 효과 설명 표시"
L["Show affix descriptions when hovering over the M+ block."] = "쐐기돌 블록 위에 마우스를 올리면 시즌 효과 설명을 표시합니다."
L["M+ completed boss display"]                         = "쐐기돌 처치 보스 표시"
L["How to show defeated bosses: checkmark icon or green color."] = "처치한 보스 표시 방식: 체크 아이콘 또는 초록색."
L["Checkmark"]                                          = "체크 표시"
L["Green color"]                                        = "초록색"

-- =====================================================================
-- OptionsData.lua Features — Achievements
-- =====================================================================
L["Show achievements"]                                  = "업적 표시"
L["Show tracked achievements in the list."]             = "추적 중인 업적을 목록에 표시합니다."
L["Show completed achievements"]                        = "완료된 업적 표시"
L["Include completed achievements in the tracker. When off, only in-progress tracked achievements are shown."] = "완료된 업적도 추적기에 표시합니다. 끄면 진행 중인 업적만 표시됩니다."
L["Show achievement icons"]                             = "업적 아이콘 표시"
L["Show each achievement's icon next to the title. Requires 'Show quest type icons' in Display."] = "각 업적의 아이콘을 제목 옆에 표시합니다. '퀘스트 유형 아이콘 표시' 옵션이 필요합니다."
L["Only show missing requirements"]                     = "미완료 조건만 표시"
L["Show only criteria you haven't completed for each tracked achievement. When off, all criteria are shown."] = "추적 중인 업적에서 미완료 조건만 표시합니다. 끄면 모든 조건을 표시합니다."

-- =====================================================================
-- OptionsData.lua Features — Endeavors
-- =====================================================================
L["Show endeavors"]                                     = "활동 과제 표시"
L["Show tracked Endeavors (Player Housing) in the list."] = "추적 중인 활동 과제(플레이어 주택)를 목록에 표시합니다."
L["Show completed endeavors"]                           = "완료된 활동 과제 표시"
L["Include completed Endeavors in the tracker. When off, only in-progress tracked Endeavors are shown."] = "완료된 활동 과제도 추적기에 표시합니다. 끄면 진행 중인 활동 과제만 표시됩니다."

-- =====================================================================
-- OptionsData.lua Features — Decor
-- =====================================================================
L["Show decor"]                                         = "장식 표시"
L["Show tracked housing decor in the list."]            = "추적 중인 주택 장식을 목록에 표시합니다."
L["Show decor icons"]                                   = "장식 아이콘 표시"
L["Show each decor item's icon next to the title. Requires 'Show quest type icons' in Display."] = "각 장식 아이템의 아이콘을 제목 옆에 표시합니다. '퀘스트 유형 아이콘 표시' 옵션이 필요합니다."

-- =====================================================================
-- OptionsData.lua Features — Scenario & Delve
-- =====================================================================
L["Show scenario events"]                               = "시나리오 이벤트 표시"
L["Show active scenario and Delve activities. Delves appear in DELVES; other scenarios in SCENARIO EVENTS."] = "활성 시나리오와 심층 탐사를 표시합니다. 심층 탐사는 DELVES에, 기타 시나리오는 SCENARIO EVENTS에 표시됩니다."
L["Hide other categories in Delve or Dungeon"]          = "심층 탐사/던전에서 다른 유형 숨기기"
L["In Delves or party dungeons, show only the Delve/Dungeon section."] = "심층 탐사 또는 파티 던전에서는 해당 구역만 표시합니다."
L["Use delve name as section header"]                    = "심층 탐사명을 구역 헤더로 사용"
L["When in a Delve, show the delve name, tier, and affixes as the section header instead of a separate banner. Disable to show the Delve block above the list."] = "심층 탐사 중일 때 별도 배너 대신 구역 헤더에 심층 탐사명, 난이도 단계, 시즌 효과를 표시합니다. 끄면 목록 위에 심층 탐사 블록이 표시됩니다."
L["Show affix names in Delves"]                         = "심층 탐사에 시즌 효과 표시"
L["Show season affix names on the first Delve entry. Requires Blizzard's objective tracker widgets to be populated; may not show when using a full tracker replacement."] = "첫 번째 심층 탐사 항목에 시즌 효과 이름을 표시합니다. Blizzard 목표 추적기 위젯이 필요하며, 전체 추적기 대체 시 표시되지 않을 수 있습니다."
L["Cinematic scenario bar"]                             = "시네마틱 시나리오 바"
L["Show timer and progress bar for scenario entries."]  = "시나리오 항목에 타이머와 진행 바를 표시합니다."
L["Scenario bar opacity"]                               = "시나리오 바 투명도"
L["Opacity of scenario timer/progress bar (0–1)."]      = "시나리오 타이머/진행 바의 투명도 (0–1)."
L["Scenario bar height"]                                = "시나리오 바 높이"
L["Height of scenario progress bar (4–8 px)."]          = "시나리오 진행 바의 높이 (4–8 px)."

-- =====================================================================
-- OptionsData.lua Typography — Font
-- =====================================================================
L["Font family."]                                       = "글꼴."
L["Header size"]                                        = "헤더 크기"
L["Header font size."]                                  = "헤더 글꼴 크기."
L["Title size"]                                         = "제목 크기"
L["Quest title font size."]                             = "퀘스트 제목 글꼴 크기."
L["Objective size"]                                     = "목표 크기"
L["Objective text font size."]                          = "목표 텍스트 글꼴 크기."
L["Zone size"]                                          = "지역 크기"
L["Zone label font size."]                              = "지역명 글꼴 크기."
L["Section size"]                                       = "구역 크기"
L["Section header font size."]                          = "구역 헤더 글꼴 크기."
L["Outline"]                                            = "외곽선"
L["Font outline style."]                                = "글꼴 외곽선 스타일."

-- =====================================================================
-- OptionsData.lua Typography — Text case
-- =====================================================================
L["Header text case"]                                   = "헤더 대소문자"
L["Display case for header."]                           = "헤더의 대소문자 표시 방식."
L["Section header case"]                                = "구역 헤더 대소문자"
L["Display case for category labels."]                  = "유형 라벨의 대소문자 표시 방식."
L["Quest title case"]                                   = "퀘스트 제목 대소문자"
L["Display case for quest titles."]                     = "퀘스트 제목의 대소문자 표시 방식."

-- =====================================================================
-- OptionsData.lua Typography — Shadow
-- =====================================================================
L["Show text shadow"]                                   = "텍스트 그림자 표시"
L["Enable drop shadow on text."]                        = "텍스트에 그림자를 표시합니다."
L["Shadow X"]                                           = "그림자 X"
L["Horizontal shadow offset."]                          = "수평 그림자 오프셋."
L["Shadow Y"]                                           = "그림자 Y"
L["Vertical shadow offset."]                            = "수직 그림자 오프셋."
L["Shadow alpha"]                                       = "그림자 투명도"
L["Shadow opacity (0–1)."]                              = "그림자 투명도 (0–1)."

-- =====================================================================
-- OptionsData.lua Typography — Mythic+ Typography
-- =====================================================================
L["Mythic+ Typography"]                                  = "쐐기돌 글꼴"
L["Dungeon name size"]                                   = "던전명 크기"
L["Font size for dungeon name (8–32 px)."]              = "던전명 글꼴 크기 (8–32 px)."
L["Dungeon name color"]                                  = "던전명 색상"
L["Text color for dungeon name."]                        = "던전명 텍스트 색상."
L["Timer size"]                                         = "타이머 크기"
L["Font size for timer (8–32 px)."]                     = "타이머 글꼴 크기 (8–32 px)."
L["Timer color"]                                        = "타이머 색상"
L["Text color for timer (in time)."]                    = "타이머 텍스트 색상 (제한 시간 내)."
L["Timer overtime color"]                               = "타이머 초과 색상"
L["Text color for timer when over the time limit."]      = "시간 초과 시 타이머 텍스트 색상."
L["Progress size"]                                      = "진행도 크기"
L["Font size for enemy forces (8–32 px)."]               = "적 병력 글꼴 크기 (8–32 px)."
L["Progress color"]                                     = "진행도 색상"
L["Text color for enemy forces."]                        = "적 병력 텍스트 색상."
L["Bar fill color"]                                     = "바 채우기 색상"
L["Progress bar fill color (in progress)."]             = "진행 바 채우기 색상 (진행 중)."
L["Bar complete color"]                                 = "바 완료 색상"
L["Progress bar fill color when enemy forces are at 100%."] = "적 병력 100% 시 진행 바 채우기 색상."
L["Affix size"]                                         = "시즌 효과 크기"
L["Font size for affixes (8–32 px)."]                   = "시즌 효과 글꼴 크기 (8–32 px)."
L["Affix color"]                                        = "시즌 효과 색상"
L["Text color for affixes."]                             = "시즌 효과 텍스트 색상."
L["Boss size"]                                          = "보스명 크기"
L["Font size for boss names (8–32 px)."]                = "보스명 글꼴 크기 (8–32 px)."
L["Boss color"]                                         = "보스명 색상"
L["Text color for boss names."]                          = "보스명 텍스트 색상."
L["Reset Mythic+ typography"]                           = "쐐기돌 글꼴 초기화"

-- =====================================================================
-- OptionsData.lua Appearance
-- =====================================================================
L["Backdrop opacity"]                                   = "배경 투명도"
L["Panel background opacity (0–1)."]                    = "패널 배경 투명도 (0–1)."
L["Show border"]                                        = "테두리 표시"
L["Show border around the tracker."]                    = "목록 주변에 테두리를 표시합니다."
L["Highlight alpha"]                                    = "강조 투명도"
L["Opacity of focused quest highlight (0–1)."]          = "포커스된 퀘스트 강조의 투명도 (0–1)."
L["Bar width"]                                          = "바 너비"
L["Width of bar-style highlights (2–6 px)."]            = "바 스타일 강조의 너비 (2–6 px)."

-- =====================================================================
-- OptionsData.lua Organization
-- =====================================================================
L["Focus category order"]                               = "퀘스트 목록 유형 순서"
L["Drag to reorder categories. DELVES and SCENARIO EVENTS stay first."] = "드래그하여 유형 순서를 변경합니다. DELVES와 SCENARIO EVENTS는 항상 최상위에 고정됩니다."
L["Focus sort mode"]                                    = "퀘스트 목록 정렬 방식"
L["Order of entries within each category."]             = "각 유형 내 항목의 정렬 순서."
L["Auto-track accepted quests"]                         = "수락한 퀘스트 자동 추적"
L["When you accept a quest (quest log only, not world quests), add it to the tracker automatically."] = "퀘스트를 수락하면 목록에 자동으로 추가합니다 (퀘스트 목록만 해당, 월드 퀘스트 제외)."
L["Require Ctrl for focus & remove"]                    = "퀘스트 목록/제거 시 Ctrl 필요"
L["Require Ctrl for focus/add (Left) and unfocus/untrack (Right) to prevent misclicks."] = "클릭을 방지하기 위해 퀘스트 목록/추가(좌클릭)와 해제/추적 중지(우클릭) 시 Ctrl 키를 요구합니다."
L["Animations"]                                         = "애니메이션"
L["Enable slide and fade for quests."]                  = "퀘스트에 슬라이드 및 페이드 효과를 활성화합니다."
L["Objective progress flash"]                           = "목표 완료 효과"
L["Show flash when an objective completes."]            = "목표 완료 시 효과를 표시합니다."
L["Flash intensity"]                                   = "효과 강도"
L["How noticeable the objective-complete flash is."]    = "목표 완료 시 표시되는 효과의 강도입니다."
L["Flash color"]                                        = "효과 색상"
L["Color of the objective-complete flash."]             = "목표 완료 시 표시되는 효과의 색상입니다."
L["Subtle"]                                             = "은은함"
L["Medium"]                                             = "보통"
L["Strong"]                                             = "강함"
L["Require Ctrl for click to complete"]                 = "클릭 완료 시 Ctrl 필요"
L["When on, requires Ctrl+Left-click to complete auto-complete quests. When off, plain Left-click completes them (Blizzard default). Only affects quests that can be completed by click (no NPC turn-in needed)."] = "활성화하면 자동 완료 퀘스트를 완료할 때 Ctrl+좌클릭이 필요합니다. 비활성화하면 일반 좌클릭으로 완료됩니다 (Blizzard 기본값). NPC 제출 없이 클릭으로 완료 가능한 퀘스트에만 적용됩니다."
L["Suppress untracked until reload"]                     = "재접속 전까지 추적 해제 숨기기"
L["When on, right-click untrack on world quests and in-zone weeklies/dailies hides them until you reload or start a new session. When off, they reappear when you return to the zone."] = "활성화하면 월드 퀘스트와 지역 내 주간·일일 퀘스트에서 우클릭 추적 해제 시 재접속할 때까지 숨깁니다. 비활성화하면 해당 지역에 돌아오면 다시 표시됩니다."
L["Permanently suppress untracked quests"]               = "추적 해제한 퀘스트 영구 숨기기"
L["When on, right-click untracked world quests and in-zone weeklies/dailies are hidden permanently (persists across reloads). Takes priority over 'Suppress until reload'. Accepting a suppressed quest removes it from the blacklist."] = "활성화하면 우클릭 추적 해제한 월드 퀘스트와 지역 내 주간·일일 퀘스트가 영구적으로 숨겨집니다 (재접속 후에도 유지). '재접속 전까지 숨기기'보다 우선합니다. 숨긴 퀘스트를 수락하면 차단 목록에서 제거됩니다."

-- =====================================================================
-- OptionsData.lua Blacklist
-- =====================================================================
L["Blacklisted quests"]                                  = "차단된 퀘스트"
L["Permanently suppressed quests"]                       = "영구 숨김 퀘스트"
L["Right-click untrack quests with 'Permanently suppress untracked quests' enabled to add them here."] = "'추적 해제한 퀘스트 영구 숨기기'가 활성화된 상태에서 우클릭 추적 해제한 퀘스트가 여기에 추가됩니다."

-- =====================================================================
-- OptionsData.lua Presence
-- =====================================================================
L["Show quest type icons"]                              = "퀘스트 유형 아이콘 표시"
L["Show quest type icon on Presence toasts and in the Focus tracker (quest accept/complete, world quest, quest update)."] = "유형 알림과 목록에 퀘스트 유형 아이콘을 표시합니다\n(퀘스트 수락/완료, 월드 퀘스트, 퀘스트 갱신)."
L["Presence icon size"]                                 = "아이콘 크기"
L["Quest icon size on toasts (16–36 px). Default 24."]  = "알림의 퀘스트 아이콘 크기 (16–36 px). 기본값 24."
L["Show discovery line"]                                = "발견 텍스트 표시"
L["Show 'Discovered' under zone/subzone when entering a new area."] = "새 지역에 진입할 때 지역/하위 지역 아래에 '발견' 텍스트를 표시합니다."

-- =====================================================================
-- OptionsData.lua Dropdown options — Outline
-- =====================================================================
L["None"]                                               = "없음"
L["Thick Outline"]                                      = "두꺼운 외곽선"

-- =====================================================================
-- OptionsData.lua Dropdown options — Highlight style
-- =====================================================================
L["Bar (left edge)"]                                    = "바 (왼쪽)"
L["Bar (right edge)"]                                   = "바 (오른쪽)"
L["Bar (top edge)"]                                     = "바 (위)"
L["Bar (bottom edge)"]                                  = "바 (아래)"
L["Outline only"]                                       = "외곽선만"
L["Soft glow"]                                          = "은은한 발광"
L["Dual edge bars"]                                     = "양쪽 바"
L["Pill left accent"]                                   = "알약형 왼쪽 강조"

-- =====================================================================
-- OptionsData.lua Dropdown options — M+ position
-- =====================================================================
L["Top"]                                                = "상단"
L["Bottom"]                                             = "하단"

-- =====================================================================
-- OptionsData.lua Dropdown options — Text case
-- =====================================================================
L["Lower Case"]                                         = "소문자"
L["Upper Case"]                                         = "대문자"
L["Proper"]                                             = "첫 글자만 대문자"

-- =====================================================================
-- OptionsData.lua Dropdown options — Header count format
-- =====================================================================
L["Tracked / in log"]                                   = "추적 중 / 목록"
L["In log / max slots"]                                 = "목록 / 최대 목록"

-- =====================================================================
-- OptionsData.lua Dropdown options — Sort mode
-- =====================================================================
L["Alphabetical"]                                       = "이름순"
L["Quest Type"]                                         = "퀘스트 유형"
L["Quest Level"]                                        = "퀘스트 레벨"

-- =====================================================================
-- OptionsData.lua Misc
-- =====================================================================
L["Custom"]                                             = "사용자 지정"
L["Order"]                                              = "순서"

-- =====================================================================
-- Tracker section labels (SECTION_LABELS)
-- =====================================================================
L["DUNGEON"]           = "던전"
L["DELVES"]            = "심층 탐사"
L["SCENARIO EVENTS"]   = "시나리오 이벤트"
L["AVAILABLE IN ZONE"] = "지역 내 수락 가능"
L["CURRENT ZONE"]      = "현재 지역"
L["CAMPAIGN"]          = "캠페인"
L["IMPORTANT"]         = "중요"
L["LEGENDARY"]         = "전설"
L["WORLD QUESTS"]      = "월드 퀘스트"
L["WEEKLY QUESTS"]     = "주간 퀘스트"
L["DAILY QUESTS"]      = "일일 퀘스트"
L["RARE BOSSES"]       = "희귀 보스"
L["ACHIEVEMENTS"]      = "업적"
L["ENDEAVORS"]         = "활동 과제"
L["DECOR"]             = "장식"
L["QUESTS"]            = "퀘스트"
L["READY TO TURN IN"]  = "보고 가능"

-- =====================================================================
-- Core.lua, FocusLayout.lua, PresenceCore.lua, FocusUnacceptedPopup.lua
-- =====================================================================
L["OBJECTIVES"]                                                                                    = "목표"
L["Options"]                                                                                       = "옵션"
L["Discovered"]                                                                                    = "발견됨"
L["Refresh"]                                                                                       = "새로고침"
L["Best-effort only. Some unaccepted quests are not exposed until you interact with NPCs or meet phasing conditions."] = "최선을 다해 검색합니다. 일부 미수락 퀘스트는 NPC와 상호작용하거나 페이징 조건을 만족해야 노출됩니다."
L["Unaccepted Quests - %s (map %s) - %d match(es)"]                                                  = "미수락 퀘스트 - %s (맵 %s) - %d건 일치"
