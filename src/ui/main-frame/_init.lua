local ADDON_NAME, Addon = ...
local Actions = Addon:GetModule("Actions") --- @type Actions
local Colors = Addon:GetModule("Colors") ---@type Colors
local Commands = Addon:GetModule("Commands")
local L = Addon:GetModule("Locale") ---@type Locale
local Lists = Addon:GetModule("Lists")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local Popup = Addon:GetModule("Popup")
local StateManager = Addon:GetModule("StateManager") ---@type StateManager
local UserInterface = Addon:GetModule("UserInterface")
local Widgets = Addon:GetModule("Widgets") ---@type Widgets

-- ============================================================================
-- UserInterface
-- ============================================================================

function UserInterface:Show()
  self.frame:Show()
end

function UserInterface:Hide()
  self.frame:Hide()
end

function UserInterface:Toggle()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

UserInterface.frame = (function()
  local NUM_LIST_FRAME_BUTTONS = 7
  local OPTIONS_FRAME_WIDTH = 250
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

  --- @class UserInterfaceFrameWidget : TitleFrameWidget
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_ParentFrame",
    width = TOTAL_FRAME_WIDTH,
    height = 600,
    titleText = Colors.Blue(ADDON_NAME),
  })

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
      { "TOPRIGHT",    frame.closeButton, "TOPLEFT",    0, 0 },
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
      { "TOPRIGHT",    frame.keybindsButton, "TOPLEFT",    0, 0 },
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

  --- @class UserInterfaceSearchBoxWidget : EditBox
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
      { "TOPLEFT",    frame.titleButton, "BOTTOMLEFT", Widgets:Padding(), 0 },
      { "BOTTOMLEFT", frame,             "BOTTOMLEFT", Widgets:Padding(), Widgets:Padding() }
    },
    width = OPTIONS_FRAME_WIDTH,
    titleText = L.OPTIONS_TEXT
  })
  frame.optionsFrame:AddOption({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return StateManager:GetPercharState().characterSpecificSettings end,
    set = function() StateManager:GetStore():Dispatch(Actions:ToggleCharacterSpecificSettings()) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return StateManager:GetCurrentState().chatMessages end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetChatMessages(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.BAG_ITEM_ICONS_TEXT,
    tooltipText = L.BAG_ITEM_ICONS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().itemIcons end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemIcons(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().itemTooltips end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetItemTooltips(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.MERCHANT_BUTTON_TEXT,
    tooltipText = L.MERCHANT_BUTTON_TOOLTIP,
    get = function() return StateManager:GetCurrentState().merchantButton end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetMerchantButton(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.MINIMAP_ICON_TEXT,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.AUTO_JUNK_FRAME_TEXT,
    tooltipText = L.AUTO_JUNK_FRAME_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoJunkFrame end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoJunkFrame(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoRepair end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoRepair(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return StateManager:GetCurrentState().autoSell end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetAutoSell(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return StateManager:GetCurrentState().safeMode end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetSafeMode(value)) end
  })
  if not Addon.IS_VANILLA then
    frame.optionsFrame:AddOption({
      labelText = L.EXCLUDE_EQUIPMENT_SETS_TEXT,
      tooltipText = L.EXCLUDE_EQUIPMENT_SETS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().excludeEquipmentSets end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeEquipmentSets(value)) end
    })
  end
  frame.optionsFrame:AddOption({
    labelText = L.EXCLUDE_UNBOUND_EQUIPMENT_TEXT,
    tooltipText = L.EXCLUDE_UNBOUND_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().excludeUnboundEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetExcludeUnboundEquipment(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.INCLUDE_POOR_ITEMS_TEXT,
    tooltipText = L.INCLUDE_POOR_ITEMS_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includePoorItems end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludePoorItems(value)) end
  })
  frame.optionsFrame:AddOption({
    labelText = L.INCLUDE_BELOW_ITEM_LEVEL_TEXT,
    onUpdateTooltip = function(self, tooltip)
      local itemLevel = Colors.White(StateManager:GetCurrentState().includeBelowItemLevel.value)
      tooltip:SetText(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT)
      tooltip:AddLine(L.INCLUDE_BELOW_ITEM_LEVEL_TOOLTIP:format(itemLevel))
    end,
    get = function() return StateManager:GetCurrentState().includeBelowItemLevel.enabled end,
    set = function(value)
      if value then
        local currentState = StateManager:GetCurrentState()
        Popup:GetInteger({
          text = Colors.Gold(L.INCLUDE_BELOW_ITEM_LEVEL_TEXT) .. "|n|n" .. L.INCLUDE_BELOW_ITEM_LEVEL_POPUP_HELP,
          initialValue = currentState.includeBelowItemLevel.value,
          onAccept = function(self, value)
            StateManager:GetStore():Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = true, value = value }))
          end
        })
      else
        StateManager:GetStore():Dispatch(Actions:PatchIncludeBelowItemLevel({ enabled = value }))
      end
    end
  })
  frame.optionsFrame:AddOption({
    labelText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TEXT,
    tooltipText = L.INCLUDE_UNSUITABLE_EQUIPMENT_TOOLTIP,
    get = function() return StateManager:GetCurrentState().includeUnsuitableEquipment end,
    set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeUnsuitableEquipment(value)) end
  })

  if Addon.IS_RETAIL then
    frame.optionsFrame:AddOption({
      labelText = L.INCLUDE_ARTIFACT_RELICS_TEXT,
      tooltipText = L.INCLUDE_ARTIFACT_RELICS_TOOLTIP,
      get = function() return StateManager:GetCurrentState().includeArtifactRelics end,
      set = function(value) StateManager:GetStore():Dispatch(Actions:SetIncludeArtifactRelics(value)) end
    })
  end

  -- Global inclusions frame.
  frame.globalInclusionsFrame = Widgets:ListFrame({
    name = "$parent_GlobalInclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT",    frame.optionsFrame, "TOPRIGHT", Widgets:Padding(0.5), 0 },
      { "BOTTOMLEFT", frame.optionsFrame, "RIGHT",    Widgets:Padding(0.5), Widgets:Padding(0.25) }
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
      { "TOPLEFT",    frame.globalInclusionsFrame, "TOPRIGHT",   Widgets:Padding(0.5), 0 },
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
      { "TOPLEFT",    frame.optionsFrame, "RIGHT",       Widgets:Padding(0.5), -Widgets:Padding(0.25) },
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
      { "TOPLEFT",    frame.percharInclusionsFrame, "TOPRIGHT",   Widgets:Padding(0.5), 0 },
      { "BOTTOMLEFT", frame.percharInclusionsFrame, "BOTTOMLEFT", Widgets:Padding(0.5), 0 }
    },
    width = LIST_FRAME_WIDTH,
    numButtons = NUM_LIST_FRAME_BUTTONS,
    list = Lists.PerCharExclusions,
    getListSearchState = getListSearchState
  })

  return frame
end)()
