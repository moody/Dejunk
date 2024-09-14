local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local MainWindowOptions = Addon:GetModule("MainWindowOptions")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindow
local MainWindow = Addon:GetModule("MainWindow")

-- ============================================================================
-- MainWindow
-- ============================================================================

function MainWindow:Show()
  self.frame:Show()
end

function MainWindow:Hide()
  self.frame:Hide()
end

function MainWindow:Toggle()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

MainWindow.frame = (function()
  local NUM_LIST_FRAME_BUTTONS = 7
  local OPTIONS_FRAME_WIDTH = 275
  local LIST_FRAME_WIDTH = 250
  local TOTAL_FRAME_WIDTH = (
    Widgets:Padding() +
    OPTIONS_FRAME_WIDTH +
    Widgets:Padding(0.5) +
    LIST_FRAME_WIDTH +
    Widgets:Padding(0.5) +
    LIST_FRAME_WIDTH +
    Widgets:Padding()
  )

  --- @class MainWindowWidget : WindowWidget
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_MainWindow",
    width = TOTAL_FRAME_WIDTH,
    height = 600,
    titleText = Colors.Blue(ADDON_NAME),
    enableClickHandling = true
  })

  frame:SetClickHandler("RightButton", "SHIFT", function()
    StateManager:Dispatch(Actions:ResetMainWindowPoint())
  end)

  Widgets:ConfigureForPointSync(frame, "MainWindow")

  -- Version text.
  frame.versionText = frame.titleButton:CreateFontString("$parent_VersionText", "ARTWORK", "GameFontNormalSmall")
  frame.versionText:SetPoint("CENTER")
  frame.versionText:SetText(Colors.White(Addon.VERSION))
  frame.versionText:SetAlpha(0.5)

  -- Keybinds button.
  frame.keybindsButton = Widgets:TitleFrameIconButton({
    name = "$parent_KeybindsButton",
    parent = frame.titleButton,
    points = {
      { "TOPRIGHT", frame.closeButton, "TOPLEFT", 0, 0 },
      { "BOTTOMRIGHT", frame.closeButton, "BOTTOMLEFT", 0, 0 }
    },
    texture = Addon:GetAsset("keyboard-icon"),
    textureSize = frame.title:GetStringHeight(),
    highlightColor = Colors.Blue,
    onClick = Commands.keybinds,
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(L.KEYBINDS)
    end
  })

  --- @class ListSearchState
  local listSearchState = {
    isSearching = false,
    searchText = ""
  }

  local function getListSearchState()
    return listSearchState
  end

  local function startSearching()
    frame.searchBox:Show()
    frame.searchBox:SetText("")
    frame.searchBox:SetFocus()
    frame.searchButton.texture:SetTexture(Addon:GetAsset("ban-icon"))
    frame.title:Hide()
    frame.versionText:Hide()
    listSearchState.isSearching = true
  end

  local function stopSearching()
    frame.title:Show()
    frame.versionText:Show()
    frame.searchBox:Hide()
    frame.searchButton.texture:SetTexture(Addon:GetAsset("search-icon"))
    listSearchState.isSearching = false
  end
  frame:HookScript("OnHide", stopSearching)

  local function toggleSearching()
    if not listSearchState.isSearching then
      startSearching()
    else
      stopSearching()
    end
  end

  -- Search button.
  frame.searchButton = Widgets:TitleFrameIconButton({
    name = "$parent_SearchButton",
    parent = frame.titleButton,
    points = {
      { "TOPRIGHT", frame.keybindsButton, "TOPLEFT", 0, 0 },
      { "BOTTOMRIGHT", frame.keybindsButton, "BOTTOMLEFT", 0, 0 }
    },
    texture = Addon:GetAsset("search-icon"),
    textureSize = frame.title:GetStringHeight(),
    highlightColor = Colors.Yellow,
    onClick = toggleSearching,
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(listSearchState.isSearching and L.CLEAR_SEARCH or L.SEARCH_LISTS)
    end
  })

  --- @class MainWindowSearchBoxWidget : EditBox
  frame.searchBox = CreateFrame("EditBox", "$parent_SearchBox", frame.titleButton)
  frame.searchBox:SetFontObject("GameFontNormalLarge")
  frame.searchBox:SetTextColor(1, 1, 1)
  frame.searchBox:SetAutoFocus(false)
  frame.searchBox:SetMultiLine(false)
  frame.searchBox:SetCountInvisibleLetters(true)
  frame.searchBox:SetPoint("TOPLEFT", Widgets:Padding(), 0)
  frame.searchBox:SetPoint("BOTTOMLEFT", Widgets:Padding(), 0)
  frame.searchBox:SetPoint("TOPRIGHT", frame.searchButton, "TOPLEFT", 0, 0)
  frame.searchBox:SetPoint("BOTTOMRIGHT", frame.searchButton, "BOTTOMLEFT", 0, 0)
  frame.searchBox:Hide()

  -- Search box placeholder text.
  frame.searchBox.placeholderText = frame.searchBox:CreateFontString("$parent_PlaceholderText", "ARTWORK",
    "GameFontNormalLarge")
  frame.searchBox.placeholderText:SetText(Colors.White(L.SEARCH_LISTS))
  frame.searchBox.placeholderText:SetPoint("LEFT")
  frame.searchBox.placeholderText:SetPoint("RIGHT")
  frame.searchBox.placeholderText:SetJustifyH("LEFT")
  frame.searchBox.placeholderText:SetAlpha(0.5)

  frame.searchBox:SetScript("OnEscapePressed", stopSearching)
  frame.searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  frame.searchBox:SetScript("OnTextChanged", function(self)
    listSearchState.searchText = self:GetText()
    if listSearchState.searchText == "" then
      self.placeholderText:Show()
    else
      self.placeholderText:Hide()
    end
  end)

  -- Options frame.
  frame.optionsFrame = Widgets:OptionsFrame({
    name = "$parent_OptionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.titleButton, "BOTTOMLEFT", Widgets:Padding(), 0 },
      { "BOTTOMLEFT", frame, "BOTTOMLEFT", Widgets:Padding(), Widgets:Padding() }
    },
    width = OPTIONS_FRAME_WIDTH,
    titleText = L.OPTIONS_TEXT
  })
  MainWindowOptions:Initialize(frame.optionsFrame)

  -- Global inclusions frame.
  frame.globalInclusionsFrame = Widgets:ListFrame({
    name = "$parent_GlobalInclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.optionsFrame, "TOPRIGHT", Widgets:Padding(0.5), 0 },
      { "BOTTOMLEFT", frame.optionsFrame, "RIGHT", Widgets:Padding(0.5), Widgets:Padding(0.25) }
    },
    width = LIST_FRAME_WIDTH,
    numButtons = NUM_LIST_FRAME_BUTTONS,
    list = Lists.GlobalInclusions,
    getListSearchState = getListSearchState
  })

  -- Global exclusions frame.
  frame.globalExclusionsFrame = Widgets:ListFrame({
    name = "$parent_GlobalExclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.globalInclusionsFrame, "TOPRIGHT", Widgets:Padding(0.5), 0 },
      { "BOTTOMLEFT", frame.globalInclusionsFrame, "BOTTOMLEFT", Widgets:Padding(0.5), 0 }
    },
    width = LIST_FRAME_WIDTH,
    numButtons = NUM_LIST_FRAME_BUTTONS,
    list = Lists.GlobalExclusions,
    getListSearchState = getListSearchState
  })

  -- Perchar inclusions frame.
  frame.percharInclusionsFrame = Widgets:ListFrame({
    name = "$parent_PercharInclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.optionsFrame, "RIGHT", Widgets:Padding(0.5), -Widgets:Padding(0.25) },
      { "BOTTOMLEFT", frame.optionsFrame, "BOTTOMRIGHT", Widgets:Padding(0.5), 0 }
    },
    width = LIST_FRAME_WIDTH,
    numButtons = NUM_LIST_FRAME_BUTTONS,
    list = Lists.PerCharInclusions,
    getListSearchState = getListSearchState
  })

  -- Perchar exclusions frame.
  frame.percharExclusionsFrame = Widgets:ListFrame({
    name = "$parent_PercharExclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.percharInclusionsFrame, "TOPRIGHT", Widgets:Padding(0.5), 0 },
      { "BOTTOMLEFT", frame.percharInclusionsFrame, "BOTTOMLEFT", Widgets:Padding(0.5), 0 }
    },
    width = LIST_FRAME_WIDTH,
    numButtons = NUM_LIST_FRAME_BUTTONS,
    list = Lists.PerCharExclusions,
    getListSearchState = getListSearchState
  })

  return frame
end)()
