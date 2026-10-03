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

  --- Text the lists are filtered by.
  searchText = ""
}

--- Selects the given sidebar row and shows its screen, hiding the previous one.
--- @param row SelectableRowComponent
--- @param screen WaffleFlexComponent
function Controller:ShowScreen(row, screen)
  if self.selectedRow then self.selectedRow:SetSelected(false) end
  row:SetSelected(true)
  self.selectedRow = row

  if screen == self.currentScreen then return end
  if self.currentScreen then self.currentScreen:SetVisibility("GONE") end
  screen:SetVisibility("VISIBLE")
  self.currentScreen = screen
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

-- Clear the search whenever the window hides.
Components.Root:WhenFrameReady(function(frame)
  frame:HookScript("OnHide", function()
    local searchBox = Components.SearchBox:GetFrame()
    if searchBox then searchBox:SetText("") end
  end)
end)

-- Window()'s generic title text goes unused in favor of the title bar below.
Components.Root.TitleText:Detach()
Components.Root.TitleText = nil

-- ============================================================================
-- Title Bar Components
-- ============================================================================

Components.TitleBarNameText = Components.Root.TitleRow:AddRow()
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

-- ============================================================================
-- Title Bar Button Components
-- ============================================================================

Components.TitleBarButtonsRow = Components.Root.TitleRow:AddRow({ justify = "END" })

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

-- Search box.
Components.SearchBox = Components.ListsScreen:AddChild({
  height = "AUTO",

  --- @param parent Frame
  frameFactory = function(parent)
    --- @class MainWindowSearchBoxWidget : FrameWidget, EditBox
    local searchBox = Widgets:Frame({
      name = "$parent_SearchBox",
      frameType = "EditBox",
      parent = parent
    })
    searchBox:SetBackdropColor(Colors.Black:GetRGBA(0.4))
    searchBox:SetFontObject("GameFontNormal")
    searchBox:SetTextColor(Colors.White:GetRGB())
    searchBox:SetAutoFocus(false)
    searchBox:SetMultiLine(false)
    searchBox:SetCountInvisibleLetters(true)

    -- Text inset, leaving room for the button.
    local textInset = Widgets:Padding()
    local buttonWidth = 46
    searchBox:SetTextInsets(textInset, buttonWidth, 0, 0)

    -- Placeholder text.
    searchBox.placeholderText = searchBox:CreateFontString("$parent_PlaceholderText", "ARTWORK", "GameFontNormal")
    searchBox.placeholderText:SetText(L.SEARCH_LISTS)
    searchBox.placeholderText:SetTextColor(Colors.Grey:GetRGB())
    searchBox.placeholderText:SetPoint("LEFT", textInset, 0)
    searchBox.placeholderText:SetPoint("RIGHT", -buttonWidth, 0)
    searchBox.placeholderText:SetJustifyH("LEFT")

    -- Button: focuses the empty box, or clears it once there is text.
    local button = Widgets:Frame({
      parent = searchBox,
      frameType = "Button",
      width = buttonWidth,
      onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(searchBox:GetText() == "" and L.SEARCH_LISTS or L.CLEAR_SEARCH)
      end
    })
    button:SetPoint("TOPRIGHT")
    button:SetPoint("BOTTOMRIGHT")
    button:SetBackdropColor(0, 0, 0, 0)
    button:SetBackdropBorderColor(0, 0, 0, 0)

    button.texture = button:CreateTexture("$parent_Texture", "ARTWORK")
    button.texture:SetTexture(Addon:GetAsset("search-icon"))
    button.texture:SetSize(14, 14)
    button.texture:SetPoint("CENTER")

    --- Brightens the border while hovered or focused.
    local function refreshBorder()
      if searchBox:HasFocus() then
        searchBox:SetBackdropBorderColor(Colors.Blue:GetRGBA(0.75))
      else
        searchBox:SetBackdropBorderColor(Colors.White:GetRGBA(searchBox:IsMouseOver() and 0.4 or 0.15))
      end
    end

    --- Brightens the icon and fills the button while hovered.
    local function refreshButton()
      local isHovered = button:IsMouseOver()
      button.texture:SetAlpha(isHovered and 1 or 0.6)
      button:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.08 or 0))
    end

    refreshBorder()
    refreshButton()

    button:HookScript("OnEnter", function() refreshButton() refreshBorder() end)
    button:HookScript("OnLeave", function() refreshButton() refreshBorder() end)
    button:SetScript("OnClick", function()
      if searchBox:GetText() ~= "" then searchBox:SetText("") end
      searchBox:SetFocus()
    end)

    searchBox:SetScript("OnEnter", refreshBorder)
    searchBox:SetScript("OnLeave", refreshBorder)
    searchBox:SetScript("OnEditFocusGained", refreshBorder)
    searchBox:SetScript("OnEditFocusLost", refreshBorder)
    searchBox:SetScript("OnEscapePressed", function(self)
      self:SetText("")
      self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnTextChanged", function(self)
      Controller.searchText = self:GetText()
      self.placeholderText:SetShown(Controller.searchText == "")
      button.texture:SetTexture(Addon:GetAsset(Controller.searchText == "" and "search-icon" or "ban-icon"))
    end)

    return searchBox
  end,

  --- @param searchBox MainWindowSearchBoxWidget
  --- @param width number
  onMeasure = function(searchBox, width)
    local _, fontHeight = searchBox:GetFont()
    return width, fontHeight + Widgets:Padding(2)
  end
})

-- Divider below the search box.
Components.ListsScreen:AttachComponent(ComponentFactory:Divider())

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
          getSearchText = function() return Controller.searchText end
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
          getSearchText = function() return Controller.searchText end
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
          getSearchText = function() return Controller.searchText end
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
          getSearchText = function() return Controller.searchText end
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

  local screens = {
    { Components.GlobalOptionsRow, Components.GlobalOptionsScreen },
    { Components.ProfileOptionsRow, Components.ProfileOptionsScreen },
    { Components.ListsRow, Components.ListsScreen }
  }

  for _, screen in ipairs(screens) do
    Controller:ShowScreen(screen[1], screen[2])
    Components.Root:Layout()
  end

  MainWindow:Hide()
end)
