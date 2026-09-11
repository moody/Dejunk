local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local MainWindowOptions = Addon:GetModule("MainWindowOptions")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindow
local MainWindow = Addon:GetModule("MainWindow")

local NUM_LIST_FRAME_BUTTONS = 7

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- @class ListSearchState
local listSearchState = {
  isSearching = false,
  searchText = ""
}

local function getListSearchState()
  return listSearchState
end

local function startSearching()
  listSearchState.isSearching = true
  listSearchState.searchText = ""
  Components.TitleText:SetHidden(true)
  Components.VersionText:SetHidden(true)
  Components.SearchBarRow:SetHidden(false)
  Components.TitleRowButtons:SetWidth("AUTO")
  if Components.SearchButton:GetFrame() then
    Components.SearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("ban-icon"))
  end
end

local function stopSearching()
  listSearchState.isSearching = false
  listSearchState.searchText = ""
  Components.TitleText:SetHidden(false)
  Components.VersionText:SetHidden(false)
  Components.SearchBarRow:SetHidden(true)
  Components.TitleRowButtons:SetWidth(nil)
  if Components.SearchButton:GetFrame() then
    Components.SearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("search-icon"))
  end
end

local function toggleSearching()
  if not listSearchState.isSearching then
    startSearching()
  else
    stopSearching()
  end
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = Addon.Waffle:Flex({
  width = 800,
  height = 600,
  direction = "COLUMN",
  hidden = true,

  defaultFrameFactory = function(parent)
    return CreateFrame("Frame")
  end,

  frameFactory = function(parent)
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_MainWindowNew",
      enableClickHandling = true,
      enableDragging = true
    })

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.mainWindow.reset())
    end)

    Widgets:ConfigureForPointSync(frame, "MainWindow")

    table.insert(UISpecialFrames, frame:GetName())

    frame:HookScript("OnHide", function()
      Components.Root:SetHidden(true)
      stopSearching()
    end)

    TickerManager:NewTicker(1 / 30, function()
      Components.Root:Layout()
    end):BindFrame(frame)

    frame:Hide()
    return frame
  end
})


-- ============================================================================
-- Title Components
-- ============================================================================

Components.TitleRow = Components.Root:AddRow({
  height = 32,
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

Components.TitleText = Components.TitleRow:AddRow({ paddingLeft = Widgets:Padding() })
Components.TitleText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Blue(ADDON_NAME))
    return fontString
  end
})

Components.VersionText = Components.TitleRow:AddRow({ justify = "CENTER" })
Components.VersionText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_VersionText", "ARTWORK", "GameFontNormalSmall")
    fontString:SetText(Colors.Grey(Addon.VERSION))
    return fontString
  end
})

Components.SearchBarRow = Components.TitleRow:AddRow({ hidden = true })
Components.SearchBarRow:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    --- @class MainWindowSearchBoxWidget : EditBox
    local searchBox = CreateFrame("EditBox", "$parent_SearchBox", parent)
    searchBox:SetFontObject("GameFontNormalLarge")
    searchBox:SetTextColor(1, 1, 1)
    searchBox:SetAutoFocus(false)
    searchBox:SetMultiLine(false)
    searchBox:SetCountInvisibleLetters(true)
    searchBox:Hide()

    -- Search box backdrop.
    Mixin(searchBox, BackdropTemplateMixin)
    searchBox:SetBackdrop(Widgets.BORDER_BACKDROP)
    searchBox:SetBackdropColor(Colors.Pink:GetRGBA(0.2))
    searchBox:SetBackdropBorderColor(Colors.Black:GetRGBA(1))

    -- Search box text inset.
    local searchBoxTextInset = Widgets:Padding()
    searchBox:SetTextInsets(searchBoxTextInset, searchBoxTextInset, 0, 0)

    -- Search box placeholder text.
    searchBox.placeholderText = searchBox:CreateFontString("$parent_PlaceholderText", "ARTWORK",
      "GameFontNormalLarge")
    searchBox.placeholderText:SetText(Colors.White(L.SEARCH_LISTS))
    searchBox.placeholderText:SetPoint("LEFT", searchBoxTextInset, 0)
    searchBox.placeholderText:SetPoint("RIGHT", -searchBoxTextInset, 0)
    searchBox.placeholderText:SetJustifyH("LEFT")
    searchBox.placeholderText:SetAlpha(0.5)

    searchBox:SetScript("OnEscapePressed", stopSearching)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
      listSearchState.searchText = self:GetText()
      if listSearchState.searchText == "" then
        self.placeholderText:Show()
      else
        self.placeholderText:Hide()
      end
    end)
    searchBox:SetScript("OnShow", function(self)
      searchBox:SetText("")
      searchBox:SetFocus()
    end)
    searchBox:SetScript("OnHide", function(self)
      searchBox:SetText("")
      searchBox:ClearFocus()
    end)

    return searchBox
  end
})

-- ============================================================================
-- Title Row Button Components
-- ============================================================================

Components.TitleRowButtons = Components.TitleRow:AddRow({ justify = "END" })

Components.SearchButton = Components.TitleRowButtons:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_SearchButton",
      texture = Addon:GetAsset("search-icon"),
      textureSize = 16,
      highlightColor = Colors.Yellow,
      onClick = toggleSearching,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(listSearchState.isSearching and L.CLEAR_SEARCH or L.SEARCH_LISTS)
      end
    })
  end
})

Components.KeybindsButton = Components.TitleRowButtons:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_KeybindsButton",
      texture = Addon:GetAsset("keyboard-icon"),
      textureSize = 18,
      highlightColor = Colors.Blue,
      onClick = Commands.keybinds,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(L.KEYBINDS)
      end
    })
  end
})

Components.CloseButton = Components.TitleRowButtons:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_CloseButton",
      texture = Addon:GetAsset("x-icon"),
      textureSize = 14,
      highlightColor = Colors.Red,
      onClick = function() MainWindow:Hide() end
    })
  end
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.ContentRow = Components.Root:AddRow({ padding = Widgets:Padding(), gap = Widgets:Padding(0.5) })

-- Left column.
Components.ContentRowLeftColumn = Components.ContentRow:AddColumn({ gap = Widgets:Padding(0.5), width = "35%" })

-- Options frame.
Components.OptionsFrame = Components.ContentRowLeftColumn:AddChild({
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
Components.ContentRowRightColumn = Components.ContentRow:AddColumn({ gap = Widgets:Padding(0.5) })

-- Global lists row.
local globalListsRow = Components.ContentRowRightColumn:AddRow({ gap = Widgets:Padding(0.5) })
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
local profileListsRow = Components.ContentRowRightColumn:AddRow({ gap = Widgets:Padding(0.5) })
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

-- ============================================================================
-- MainWindow
-- ============================================================================

function MainWindow:Show()
  Components.Root:SetHidden(false)
  Components.Root:Layout()
end

function MainWindow:Hide()
  Components.Root:SetHidden(true)
  Components.Root:Layout()
end

function MainWindow:Toggle()
  if Components.Root:GetHidden() then
    self:Show()
  else
    self:Hide()
  end
end

-- ============================================================================
-- Events
-- ============================================================================

-- Some elements of the UI do not appear correctly without an initial load,
-- so we force one here once the Wux store is ready.
EventManager:Once(E.StoreCreated, function()
  MainWindow:Show()
  MainWindow:Hide()
end)
