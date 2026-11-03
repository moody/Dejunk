local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFrame = Addon:GetModule("JunkFrame")
local JunkItemsCache = Addon:GetModule("JunkItemsCache")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local LootableFrame = Addon:GetModule("LootableFrame")
local MainWindowOptions = Addon:GetModule("MainWindowOptions")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindow
local MainWindow = Addon:GetModule("MainWindow")

local LIST_PANEL_CARD_COUNT = 7
local LIST_PANEL_ICON_SIZE = 18

local Components = {}

-- ============================================================================
-- Controller
-- ============================================================================

--- @alias SidebarRowKey "LISTS" | "GLOBAL_OPTIONS" | "PROFILES" | "PROFILE_OPTIONS" | "KEYBINDINGS"

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

-- Reuse Window()'s close button, just moved into this row.
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
      button:PropagateWhenDisabled(true)

      Components.SearchBox.Input:WhenFrameReady(function(editBox)
        local box = Components.SearchBox:GetFrame() --- @type FrameWidget

        --- Shows the clear icon and enables the button while the box has text.
        local function refreshText()
          local hasText = editBox:GetText() ~= ""
          Components.SearchButton:SetIcon(Addon:GetAsset(hasText and "ban-icon" or "search-icon"))
          button:FireEvent("ENABLED", hasText)
        end

        --- Dims the button while it is disabled, unless the box has focus.
        local function refreshAlpha()
          local isEnabled = button:GetEventValue("ENABLED")
          button:SetAlpha((isEnabled or box:GetEventValue("FOCUSED")) and 1 or 0.4)
        end

        editBox:HookScript("OnTextChanged", refreshText)
        button:OnEvent("ENABLED", refreshAlpha)
        box:OnEvent("FOCUSED", refreshAlpha)

        refreshText()
      end)
    end)

    -- Divider below the search box.
    screen:AttachComponent(ComponentFactory:Divider()):SetMarginTop(Widgets:Padding(0.25))

    --- Returns the text the lists are filtered by.
    local function getSearchText() return Controller.searchText end

    -- Global lists row.
    local globalRow = screen:AddRow({ gap = Widgets:Padding(0.5) })
    globalRow:AttachComponent(ComponentFactory:ListPanel({
      list = Lists.GlobalInclusions,
      iconSize = LIST_PANEL_ICON_SIZE,
      cardCount = LIST_PANEL_CARD_COUNT,
      getSearchText = getSearchText
    }))
    globalRow:AttachComponent(ComponentFactory:ListPanel({
      list = Lists.GlobalExclusions,
      iconSize = LIST_PANEL_ICON_SIZE,
      cardCount = LIST_PANEL_CARD_COUNT,
      getSearchText = getSearchText
    }))

    -- Profile lists row.
    local profileRow = screen:AddRow({ gap = Widgets:Padding(0.5) })
    profileRow:AttachComponent(ComponentFactory:ListPanel({
      list = Lists.ProfileInclusions,
      iconSize = LIST_PANEL_ICON_SIZE,
      cardCount = LIST_PANEL_CARD_COUNT,
      getSearchText = getSearchText
    }))
    profileRow:AttachComponent(ComponentFactory:ListPanel({
      list = Lists.ProfileExclusions,
      iconSize = LIST_PANEL_ICON_SIZE,
      cardCount = LIST_PANEL_CARD_COUNT,
      getSearchText = getSearchText
    }))
  end
})

Controller:AddSidebarRow({
  key = "GLOBAL_OPTIONS",
  labelText = L.GLOBAL_OPTIONS_TEXT,
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateGlobalOptionsPanel()) end
})

Controller:AddSidebarRow({
  key = "PROFILE_OPTIONS",
  labelText = L.PROFILE_OPTIONS_TEXT,
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateProfileOptionsPanel()) end
})

Controller:AddSidebarRow({
  key = "PROFILES",
  labelText = L.PROFILES,
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateProfilesPanel()) end
})

Controller:AddSidebarRow({
  key = "KEYBINDINGS",
  labelText = L.KEYBINDINGS,
  createScreen = function(screen) screen:AttachComponent(MainWindowOptions:CreateKeybindingsPanel()) end
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

--- @class FooterSegmentOptions
--- @field justify "LEFT" | "CENTER" | "RIGHT" Horizontal alignment of the text.
--- @field getValue fun(): any Returns what the text shows. Called every tick; the text is rebuilt when it changes.
--- @field formatText fun(value: any): string Returns the text for the value. It is grey unless it sets its own colors.
--- @field onClick fun() Called when the segment is clicked. The segment highlights while hovered.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shown while hovering the segment.

--- Adds a segment to the footer with one line of text, which is cut short when it does not fit.
--- @param options FooterSegmentOptions
local function addFooterSegment(options)
  local segment = footerRow:AddRow({
    alignSelf = "STRETCH",
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame:SetScript("OnClick", options.onClick)

      -- Highlight the segment while it is hovered.
      frame:OnEvent("HOVERED", function()
        frame:SetBackdropColor(Colors.White:GetRGBA(frame:GetEventValue("HOVERED") and 0.08 or 0))
      end)

      return frame
    end
  })

  segment:AddChild({
    width = "100%",
    alignSelf = "STRETCH",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH(options.justify)
      fontString:SetJustifyV("MIDDLE")
      fontString:SetWordWrap(false)
      fontString:SetTextColor(Colors.Grey:GetRGB())

      -- The value the text currently shows.
      local shownValue

      TickerManager:NewTicker(1 / 30, function()
        local value = options.getValue()
        if value == shownValue then return end

        shownValue = value
        fontString:SetText(options.formatText(value))
      end):BindFrame(fontString)

      return fontString
    end
  })
end

-- Active profile. Clicking shows the Profiles screen.
addFooterSegment({
  justify = "LEFT",
  getValue = function() return StateManager:GetProfileState().name end,
  formatText = function(name) return Colors.Yellow(L.ACTIVE_PROFILE) .. " " .. Colors.White(name) end,
  onClick = function() Controller:SelectSidebarRow("PROFILES") end
})

-- Junk item counts. Clicking toggles the Junk Items frame.
addFooterSegment({
  justify = "CENTER",
  getValue = function() return JunkItemsCache:GetNumJunkItemsText() end,
  formatText = function(countsText) return Colors.Yellow(L.JUNK_ITEMS) .. " " .. countsText end,
  onClick = function() JunkFrame:Toggle() end,

  --- Spells out the two counts.
  --- @param tooltip Tooltip
  onUpdateTooltip = function(_, tooltip)
    local numSellable, numDestroyable = JunkItemsCache:GetNumJunkItems()
    tooltip:AddLine(L.JUNK_ITEMS_COUNTS:format(Colors.White(numSellable), Colors.Red(numDestroyable)))
  end
})

-- Lootable item count. Clicking toggles the Lootable Items frame.
addFooterSegment({
  justify = "RIGHT",
  getValue = function() return LootableFrame:GetNumLootableItems() end,

  formatText = function(numLootable)
    return (
      Colors.Yellow(L.LOOTABLE_ITEMS) ..
      Colors.Grey(" (") .. Colors.White(numLootable) .. Colors.Grey(")")
    )
  end,

  onClick = function() LootableFrame:Toggle() end
})

-- ============================================================================
-- MainWindow
-- ============================================================================

--- Shows the window, on the screen of the sidebar row `key` if one is given.
--- @param key? SidebarRowKey
function MainWindow:Show(key)
  if key then Controller:SelectSidebarRow(key) end

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
