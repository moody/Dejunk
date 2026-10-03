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
-- Controller
-- ============================================================================

local Controller = {
  --- Sidebar row currently selected.
  --- @type SelectableRowComponent?
  selectedRow = nil,

  --- Screen currently shown in the content area.
  --- @type WaffleFlexComponent?
  currentScreen = nil,

  --- @class ListSearchState
  listSearchState = {
    isSearching = false,
    searchText = ""
  }
}

--- Selects the given sidebar row and shows its screen, hiding the previous one.
--- Leaving the lists ends any search.
--- @param row SelectableRowComponent
--- @param screen WaffleFlexComponent
function Controller:ShowScreen(row, screen)
  if screen ~= Components.ListsScreen then self:StopSearching() end
  if self.selectedRow then self.selectedRow:SetSelected(false) end
  row:SetSelected(true)
  self.selectedRow = row

  if screen == self.currentScreen then return end
  if self.currentScreen then self.currentScreen:SetVisibility("GONE") end
  screen:SetVisibility("VISIBLE")
  self.currentScreen = screen
end

function Controller:GetListSearchState()
  return self.listSearchState
end

function Controller:StartSearching()
  self:ShowScreen(Components.ListsRow, Components.ListsScreen)
  self.listSearchState.isSearching = true
  self.listSearchState.searchText = ""
  Components.TitleBarNameText:SetVisibility("GONE")
  Components.TitleBarVersionText:SetVisibility("GONE")
  Components.TitleBarSearchRow:SetVisibility("VISIBLE")
  Components.TitleBarButtonsRow:SetWidth("AUTO")
  if Components.TitleBarSearchButton:GetFrame() then
    Components.TitleBarSearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("ban-icon"))
  end
end

function Controller:StopSearching()
  self.listSearchState.isSearching = false
  self.listSearchState.searchText = ""
  Components.TitleBarNameText:SetVisibility("VISIBLE")
  Components.TitleBarVersionText:SetVisibility("VISIBLE")
  Components.TitleBarSearchRow:SetVisibility("GONE")
  Components.TitleBarButtonsRow:SetWidth(nil)
  if Components.TitleBarSearchButton:GetFrame() then
    Components.TitleBarSearchButton:GetFrame().texture:SetTexture(Addon:GetAsset("search-icon"))
  end
end

function Controller:ToggleSearching()
  if not self.listSearchState.isSearching then
    self:StartSearching()
  else
    self:StopSearching()
  end
end

function Controller:OpenKeybindings()
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
  frame:HookScript("OnHide", function() Controller:StopSearching() end)
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
    --- @class MainWindowSearchBoxWidget : FrameWidget, EditBox
    local searchBox = Widgets:Frame({
      name = "$parent_SearchBox",
      frameType = "EditBox",
      parent = parent
    })
    searchBox:SetFontObject("GameFontNormalLarge")
    searchBox:SetTextColor(1, 1, 1)
    searchBox:SetAutoFocus(false)
    searchBox:SetMultiLine(false)
    searchBox:SetCountInvisibleLetters(true)
    searchBox:Hide()

    -- Search box backdrop.
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

    searchBox:SetScript("OnEscapePressed", function() Controller:StopSearching() end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
      Controller.listSearchState.searchText = self:GetText()
      if Controller.listSearchState.searchText == "" then
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
    onClick = function() Controller:ToggleSearching() end,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(Controller.listSearchState.isSearching and L.CLEAR_SEARCH or L.SEARCH_LISTS)
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
    onClick = function() Controller:OpenKeybindings() end,
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
          getListSearchState = function() return Controller:GetListSearchState() end
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
          getListSearchState = function() return Controller:GetListSearchState() end
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
          getListSearchState = function() return Controller:GetListSearchState() end
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
          getListSearchState = function() return Controller:GetListSearchState() end
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
  onClick = function(row) Controller:ShowScreen(row, Components.ListsScreen) end
}))

Components.GlobalOptionsRow = sidebar:AttachComponent(ComponentFactory:SelectableRow({
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.GLOBAL),
  onClick = function(row) Controller:ShowScreen(row, Components.GlobalOptionsScreen) end
}))

Components.ProfileOptionsRow = sidebar:AttachComponent(ComponentFactory:SelectableRow({
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.PROFILE),
  onClick = function(row) Controller:ShowScreen(row, Components.ProfileOptionsScreen) end
}))

Controller:ShowScreen(Components.ListsRow, Components.ListsScreen)

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
