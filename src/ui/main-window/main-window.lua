local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
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

  --- @class MainWindowWidget : WindowWidget
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_MainWindow",
    width = 800,
    height = 600,
    titleText = Colors.Blue(ADDON_NAME),
    enableClickHandling = true
  })

  frame:SetClickHandler("RightButton", "SHIFT", function()
    StateManager:Dispatch(ActionCreators.Global.points.mainWindow.reset())
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


  --- Search box.
  --- @class MainWindowSearchBoxWidget : EditBox
  frame.searchBox = CreateFrame("EditBox", "$parent_SearchBox", frame.titleButton)
  frame.searchBox:SetFontObject("GameFontNormalLarge")
  frame.searchBox:SetTextColor(1, 1, 1)
  frame.searchBox:SetAutoFocus(false)
  frame.searchBox:SetMultiLine(false)
  frame.searchBox:SetCountInvisibleLetters(true)
  frame.searchBox:SetPoint("TOPLEFT", Widgets:Padding(), -Widgets:Padding(0.5))
  frame.searchBox:SetPoint("BOTTOMLEFT", Widgets:Padding(), Widgets:Padding(0.5))
  frame.searchBox:SetPoint("RIGHT", frame.searchButton, "LEFT", 0, 0)
  -- frame.searchBox:SetPoint("BOTTOMRIGHT", frame.searchButton, "BOTTOMLEFT", 0, 0)
  frame.searchBox:Hide()

  -- Search box backdrop.
  Mixin(frame.searchBox, BackdropTemplateMixin)
  frame.searchBox:SetBackdrop(Widgets.BORDER_BACKDROP)
  frame.searchBox:SetBackdropColor(Colors.Pink:GetRGBA(0.2))
  frame.searchBox:SetBackdropBorderColor(Colors.Black:GetRGBA(1))

  -- Search box text inset.
  local searchBoxTextInset = Widgets:Padding(0.5)
  frame.searchBox:SetTextInsets(searchBoxTextInset, -searchBoxTextInset, 0, 0)

  -- Search box placeholder text.
  frame.searchBox.placeholderText = frame.searchBox:CreateFontString("$parent_PlaceholderText", "ARTWORK",
    "GameFontNormalLarge")
  frame.searchBox.placeholderText:SetText(Colors.White(L.SEARCH_LISTS))
  frame.searchBox.placeholderText:SetPoint("LEFT", searchBoxTextInset, 0)
  frame.searchBox.placeholderText:SetPoint("RIGHT", -searchBoxTextInset, 0)
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

  -- Content area, everything below the title bar.
  frame.contentFrame = CreateFrame("Frame", "$parent_Content", frame)
  frame.contentFrame:SetPoint("TOPLEFT", frame.titleButton, "BOTTOMLEFT", 0, 0)
  frame.contentFrame:SetPoint("BOTTOMRIGHT", 0, 0)

  -- Root row.
  local root = Addon.Waffle:Flex({
    frame = frame.contentFrame,
    width = frame:GetWidth(),
    height = frame:GetHeight() - frame.titleButton:GetHeight(),
    direction = "ROW",
    padding = Widgets:Padding(),
    gap = Widgets:Padding(0.5),
    defaultFrameFactory = function(parent)
      return CreateFrame("Frame", nil, parent)
    end
  })

  -- Left column.
  local leftColumn = root:AddColumn({ gap = Widgets:Padding(0.5), width = 300 })
  leftColumn:AddChild({
    frameFactory = function(parent)
      local optionsFrame = Widgets:OptionsFrame({
        parent = parent,
        name = "$parent_OptionsFrame",
        titleText = L.OPTIONS_TEXT
      })
      MainWindowOptions:Initialize(optionsFrame)
      return optionsFrame
    end
  })

  -- Right column.
  local rightColumn = root:AddColumn({ gap = Widgets:Padding(0.5) })

  -- Global lists row.
  local globalListsRow = rightColumn:AddRow({ gap = Widgets:Padding(0.5) })
  globalListsRow:AddChild({
    frameFactory = function(parent)
      return Widgets:ListFrame({
        parent = parent,
        name = "$parent_GlobalInclusionsFrame",
        numButtons = NUM_LIST_FRAME_BUTTONS,
        list = Lists.GlobalInclusions,
        getListSearchState = getListSearchState
      })
    end
  })
  globalListsRow:AddChild({
    frameFactory = function(parent)
      return Widgets:ListFrame({
        parent = parent,
        name = "$parent_GlobalExclusionsFrame",
        numButtons = NUM_LIST_FRAME_BUTTONS,
        list = Lists.GlobalExclusions,
        getListSearchState = getListSearchState
      })
    end
  })

  -- Profile lists row.
  local profileListsRow = rightColumn:AddRow({ gap = Widgets:Padding(0.5) })
  profileListsRow:AddChild({
    frameFactory = function(parent)
      return Widgets:ListFrame({
        parent = parent,
        name = "$parent_ProfileInclusionsFrame",
        numButtons = NUM_LIST_FRAME_BUTTONS,
        list = Lists.ProfileInclusions,
        getListSearchState = getListSearchState
      })
    end
  })
  profileListsRow:AddChild({
    frameFactory = function(parent)
      return Widgets:ListFrame({
        parent = parent,
        name = "$parent_ProfileExclusionsFrame",
        numButtons = NUM_LIST_FRAME_BUTTONS,
        list = Lists.ProfileExclusions,
        getListSearchState = getListSearchState
      })
    end
  })

  root:Layout()

  frame:SetScript("OnUpdate", function() root:Layout() end)

  return frame
end)()
