local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local MainWindowOptions = Addon:GetModule("MainWindowOptions")
local ProfilesFrame = Addon:GetModule("ProfilesFrame")
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

--- @type SelectableRowComponent?
local selectedRow

--- @type WaffleFlexComponent?
local currentScreen

--- Selects the given sidebar row and shows its screen, hiding the previous one.
--- @param row SelectableRowComponent
--- @param screen WaffleFlexComponent
local function showScreen(row, screen)
  if selectedRow then selectedRow:SetSelected(false) end
  row:SetSelected(true)
  selectedRow = row

  if screen == currentScreen then return end
  if currentScreen then currentScreen:SetVisibility("GONE") end
  screen:SetVisibility("VISIBLE")
  currentScreen = screen
end

--- @class ListSearchState
local listSearchState = {
  isSearching = false,
  searchText = ""
}

local function getListSearchState()
  return listSearchState
end

local function startSearching()
  showScreen(Components.ListsRow, Components.ListsScreen)
  listSearchState.isSearching = true
  listSearchState.searchText = ""
  Components.TitleBarNameText:SetVisibility("GONE")
  Components.TitleBarVersionText:SetVisibility("GONE")
  Components.TitleBarSearchRow:SetVisibility("VISIBLE")
  Components.TitleBarButtonsRow:SetWidth("AUTO")
  if Components.TitleBarSearchButton:GetFrame() then
    Components.TitleBarSearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("ban-icon"))
  end
end

local function stopSearching()
  listSearchState.isSearching = false
  listSearchState.searchText = ""
  Components.TitleBarNameText:SetVisibility("VISIBLE")
  Components.TitleBarVersionText:SetVisibility("VISIBLE")
  Components.TitleBarSearchRow:SetVisibility("GONE")
  Components.TitleBarButtonsRow:SetWidth(nil)
  if Components.TitleBarSearchButton:GetFrame() then
    Components.TitleBarSearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("search-icon"))
  end
end

local function toggleSearching()
  if not listSearchState.isSearching then
    startSearching()
  else
    stopSearching()
  end
end

local function openKeybindings()
  CloseMenus()
  CloseAllWindows()

  -- See: https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/PingSystem.lua#L76
  local keybindsCategory = SettingsPanel:GetCategory(Settings.KEYBINDINGS_CATEGORY_ID)
  local keybindsLayout = SettingsPanel:GetLayout(keybindsCategory)
  for _, initializer in keybindsLayout:EnumerateInitializers() do
    if initializer:GetName() == BINDING_CATEGORY_DEJUNK then
      initializer.data.expanded = true
      Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, BINDING_CATEGORY_DEJUNK)
      return
    end
  end
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "MainWindow",
  width = 800,
  height = 640,
  titleText = "", -- unused; MainWindow builds its own title-bar content below
  getPoint = function() return StateManager:GetGlobalState().points.mainWindow end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.mainWindow.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.mainWindow.reset()) end,
  refresh = function() Components.Root:Layout() end
})

-- Stop searching whenever the window hides.
Components.Root:WhenFrameReady(function(frame)
  frame:HookScript("OnHide", stopSearching)
end)

-- Window()'s generic title text goes unused in favor of the title bar below.
Components.Root.TitleText:Detach()
Components.Root.TitleText = nil

-- ============================================================================
-- Title Bar Components
-- ============================================================================

-- Padding moves to `TitleBarNameText` so `TitleBarSearchRow` sits flush left.
Components.Root.TitleRow:SetPaddingLeft(nil)

Components.TitleBarNameText = Components.Root.TitleRow:AddRow({ paddingLeft = Widgets:Padding() })
Components.TitleBarNameText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Blue(ADDON_NAME))
    return fontString
  end
})

Components.TitleBarVersionText = Components.Root.TitleRow:AddRow({ justify = "CENTER" })
Components.TitleBarVersionText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_VersionText", "ARTWORK", "GameFontNormalSmall")
    fontString:SetText(Colors.Grey(Addon.VERSION))
    return fontString
  end
})

Components.TitleBarSearchRow = Components.Root.TitleRow:AddRow({ visibility = "GONE" })
Components.TitleBarSearchRow:AddChild({
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
-- Title Bar Button Components
-- ============================================================================

Components.TitleBarButtonsRow = Components.Root.TitleRow:AddRow({ justify = "END" })

-- Search button.
Components.TitleBarSearchButton = Components.TitleBarButtonsRow:AttachComponent(
  ComponentFactory:WindowTitleButton({
    name = "$parent_SearchButton",
    texture = Addon:GetAsset("search-icon"),
    textureSize = 16,
    highlightColor = Colors.Pink,
    onClick = toggleSearching,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(listSearchState.isSearching and L.CLEAR_SEARCH or L.SEARCH_LISTS)
    end
  })
)

-- Keybinds button.
Components.TitleBarButtonsRow:AttachComponent(
  ComponentFactory:WindowTitleButton({
    name = "$parent_KeybindsButton",
    texture = Addon:GetAsset("keyboard-icon"),
    textureSize = 18,
    highlightColor = Colors.Blue,
    onClick = openKeybindings,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(L.KEYBINDS)
    end
  })
)

-- Reuse Window()'s close button, just moved into this row alongside the others.
Components.TitleBarButtonsRow:AttachComponent(Components.Root.CloseButton:Detach())

-- ============================================================================
-- Main Screen Components
-- ============================================================================

Components.MainScreenRow = Components.Root:AddRow({ padding = Widgets:Padding(), gap = Widgets:Padding(0.5) })

-- Sidebar.
local sidebar = Components.MainScreenRow:AddColumn({
  width = "25%",
  padding = Widgets:Padding(0.5),
  gap = Widgets:Padding(0.5),
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end
})

-- Content area: shows the screen for the selected sidebar row.
local contentArea = Components.MainScreenRow:AddColumn()

-- ============================================================================
-- Lists Screen Components
-- ============================================================================

Components.ListsScreen = contentArea:AddColumn({ gap = Widgets:Padding(0.5), visibility = "GONE" })

-- Global lists row.
Components.ListsScreen:AddRow({
  gap = Widgets:Padding(0.5),
  children = {
    {
      frameFactory = function(parent)
        return Widgets:ListFrame({
          parent = parent,
          name = "$parent_GlobalInclusionsFrame",
          numButtons = NUM_LIST_FRAME_BUTTONS,
          list = Lists.GlobalInclusions,
          getListSearchState = getListSearchState
        })
      end
    },
    {
      frameFactory = function(parent)
        return Widgets:ListFrame({
          parent = parent,
          name = "$parent_GlobalExclusionsFrame",
          numButtons = NUM_LIST_FRAME_BUTTONS,
          list = Lists.GlobalExclusions,
          getListSearchState = getListSearchState
        })
      end
    }
  }
})

-- Profile lists row.
Components.ListsScreen:AddRow({
  gap = Widgets:Padding(0.5),
  children = {
    {
      frameFactory = function(parent)
        return Widgets:ListFrame({
          parent = parent,
          name = "$parent_ProfileInclusionsFrame",
          numButtons = NUM_LIST_FRAME_BUTTONS,
          list = Lists.ProfileInclusions,
          getListSearchState = getListSearchState
        })
      end
    },
    {
      frameFactory = function(parent)
        return Widgets:ListFrame({
          parent = parent,
          name = "$parent_ProfileExclusionsFrame",
          numButtons = NUM_LIST_FRAME_BUTTONS,
          list = Lists.ProfileExclusions,
          getListSearchState = getListSearchState
        })
      end
    }
  }
})

-- ============================================================================
-- Options Screen Components
-- ============================================================================

Components.GlobalOptionsScreen = contentArea:AttachComponent(MainWindowOptions:CreateGlobalOptionsPanel())
Components.GlobalOptionsScreen:SetVisibility("GONE")

Components.ProfileOptionsScreen = contentArea:AttachComponent(MainWindowOptions:CreateProfileOptionsPanel())
Components.ProfileOptionsScreen:SetVisibility("GONE")

-- ============================================================================
-- Sidebar Components
-- ============================================================================

Components.ListsRow = sidebar:AttachComponent(ComponentFactory:SelectableRow({
  labelText = L.LISTS,
  onClick = function(row) showScreen(row, Components.ListsScreen) end
}))

Components.GlobalOptionsRow = sidebar:AttachComponent(ComponentFactory:SelectableRow({
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.GLOBAL),
  onClick = function(row) showScreen(row, Components.GlobalOptionsScreen) end
}))

Components.ProfileOptionsRow = sidebar:AttachComponent(ComponentFactory:SelectableRow({
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.PROFILE),
  onClick = function(row) showScreen(row, Components.ProfileOptionsScreen) end
}))

showScreen(Components.ListsRow, Components.ListsScreen)

-- ============================================================================
-- Footer Components
-- ============================================================================

local footerRow = Components.Root:AddRow({
  height = 28,
  order = 10,
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

-- Active profile label.
footerRow:AddRow({ paddingLeft = Widgets:Padding() }):AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_ActiveProfileLabel", "ARTWORK", "GameFontNormal")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Grey(L.ACTIVE_PROFILE))
    return fontString
  end
})

-- Active profile name, kept in sync with state.
footerRow:AddRow({ justify = "CENTER" }):AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_ActiveProfileName", "ARTWORK", "GameFontNormal")
    fontString:SetJustifyH("CENTER")
    fontString:SetText(L.DEFAULT_PROFILE_NAME)
    fontString:SetTextColor(Colors.Yellow:GetRGB())

    TickerManager:NewTicker(1 / 30, function()
      fontString:SetText(StateManager:GetProfileState().name)
    end):BindFrame(fontString)

    return fontString
  end
})

-- Edit profiles button.
footerRow:AddRow({ justify = "END" }):AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_EditProfilesButton",
      texture = Addon:GetAsset("gear-icon"),
      textureSize = 14,
      highlightColor = Colors.Yellow,
      onClick = function() ProfilesFrame:Toggle() end,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(L.PROFILES)
      end
    })
  end
})

-- ============================================================================
-- MainWindow
-- ============================================================================

function MainWindow:Show()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

function MainWindow:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

function MainWindow:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
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
