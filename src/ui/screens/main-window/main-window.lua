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

--- @alias SidebarRowKey "LISTS" | "GLOBAL_OPTIONS" | "PROFILE_OPTIONS"

--- @class SidebarRowOptions
--- @field key SidebarRowKey
--- @field labelText string Text of the sidebar row.
--- @field createScreen fun(screen: WaffleFlexComponent) Fills the screen the row shows.

local Controller = {
  --- Sidebar rows and the screens they show.
  --- @type table<SidebarRowKey, { row: SelectableRowComponent, screen: WaffleFlexComponent }>
  sidebarRows = {},

  --- Key of the selected sidebar row.
  --- @type SidebarRowKey?
  selectedRowKey = nil,

  --- Text the lists are filtered by.
  searchText = ""
}

--- Adds a sidebar row that shows a screen. The screen is created hidden and
--- filled by `options.createScreen`.
--- @param options SidebarRowOptions
function Controller:AddSidebarRow(options)
  local screen = Components.ContentArea:AddColumn({ gap = Widgets:Padding(0.5), visibility = "GONE" })
  options.createScreen(screen)

  self.sidebarRows[options.key] = {
    screen = screen,
    row = Components.Sidebar:AttachComponent(ComponentFactory:SelectableRow({
      labelText = options.labelText,
      onClick = function() self:SelectSidebarRow(options.key) end
    }))
  }
end

--- Selects the sidebar row and shows its screen, hiding the previous one.
--- @param key SidebarRowKey
function Controller:SelectSidebarRow(key)
  if key == self.selectedRowKey then return end

  local previous = self.sidebarRows[self.selectedRowKey]
  if previous then
    previous.row:SetSelected(false)
    previous.screen:SetVisibility("GONE")
  end

  self.sidebarRows[key].row:SetSelected(true)
  self.sidebarRows[key].screen:SetVisibility("VISIBLE")
  self.selectedRowKey = key
end

--- Shows every screen once so its frames are built now, then returns to the lists.
function Controller:PreloadScreens()
  for key in pairs(self.sidebarRows) do
    self:SelectSidebarRow(key)
    Components.Root:Layout()
  end

  self:SelectSidebarRow("LISTS")
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
  frame:HookScript("OnHide", function() Components.SearchBox:SetText("") end)
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
  ComponentFactory:IconButton({
    name = "$parent_KeybindsButton",
    icon = Addon:GetAsset("keyboard-icon"),
    iconSize = 18,
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
Components.Sidebar = Components.MainScreenRow:AddColumn({
  width = "25%",
  padding = Widgets:Padding(0.5),
  gap = Widgets:Padding(0.5),
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end
})

-- Content area: shows the screen of the selected sidebar row.
Components.ContentArea = Components.MainScreenRow:AddColumn()

-- ============================================================================
-- Sidebar Rows and Screens
-- ============================================================================

Controller:AddSidebarRow({
  key = "LISTS",
  labelText = L.LISTS,
  createScreen = function(screen)
    -- Search box.
    Components.SearchBox = screen:AttachComponent(ComponentFactory:TextInput({
      placeholderText = L.SEARCH_LISTS,
      fontObject = "GameFontNormal",
      onTextChanged = function(text) Controller.searchText = text end
    }))

    -- Escape clears the search.
    Components.SearchBox.Input:WhenFrameReady(function(editBox)
      editBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
      end)
    end)

    -- Search button: clears the search and the focus.
    Components.SearchButton = Components.SearchBox:AttachComponent(ComponentFactory:IconButton({
      icon = Addon:GetAsset("search-icon"),
      highlightColor = Colors.Blue,
      onClick = function()
        Components.SearchBox:SetText("")
        Components.SearchBox.Input:GetFrame():ClearFocus()
      end,
      onUpdateTooltip = function(self, tooltip)
        if not self:GetEventValue("ENABLED") then return end
        tooltip:SetText(L.CLEAR_SEARCH)
      end
    }))

    -- The button follows the box. While the box is empty, the button is disabled and dimmed unless the box has
    -- focus, and the mouse passes through it to the box.
    Components.SearchButton:WhenFrameReady(function(button)
      --- @cast button IconButtonWidget
      Components.SearchBox.Input:WhenFrameReady(function(editBox)
        local box = Components.SearchBox:GetFrame() --- @type FrameWidget

        --- Shows the clear icon and enables the button while the box has text.
        local function refreshText()
          local hasText = editBox:GetText() ~= ""
          Components.SearchButton:SetIcon(Addon:GetAsset(hasText and "ban-icon" or "search-icon"))
          button:FireEvent("ENABLED", hasText)
        end

        --- Dims the button and passes the mouse through while it is disabled.
        local function refreshMouse()
          local isEnabled = button:GetEventValue("ENABLED")
          button:SetAlpha((isEnabled or box:GetEventValue("FOCUSED")) and 1 or 0.4)
          button:SetPropagateMouseClicks(not isEnabled)
          button:SetPropagateMouseMotion(not isEnabled)
        end

        editBox:HookScript("OnTextChanged", refreshText)
        button:OnEvent("ENABLED", refreshMouse)
        box:OnEvent("FOCUSED", refreshMouse)

        refreshText()
      end)
    end)

    -- Divider below the search box.
    screen:AttachComponent(ComponentFactory:Divider()):SetMarginTop(Widgets:Padding(0.25))

    -- Global lists row.
    screen:AddRow({
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
    screen:AddRow({
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
  end
})

Controller:AddSidebarRow({
  key = "GLOBAL_OPTIONS",
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.GLOBAL),
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateGlobalOptionsPanel()) end
})

Controller:AddSidebarRow({
  key = "PROFILE_OPTIONS",
  labelText = ("%s (%s)"):format(L.OPTIONS_TEXT, L.PROFILE),
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateProfileOptionsPanel()) end
})

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
  Controller:PreloadScreens()
  MainWindow:Hide()
end)
