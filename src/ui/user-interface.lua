local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local L = Addon.Locale
local SavedVariables = Addon.SavedVariables
local UserInterface = Addon.UserInterface
local Widgets = Addon.UserInterface.Widgets

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
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_ParentFrame",
    width = 650,
    height = 500,
    titleText = Colors.Blue(ADDON_NAME),
  })

  -- Version text.
  frame.versionText = frame:CreateFontString("$parent_VersionText", "ARTWORK", "GameFontNormalSmall")
  frame.versionText:SetPoint("TOP", frame, 0, -Widgets:Padding(1.5))
  frame.versionText:SetText(Colors.White(Addon.VERSION))
  frame.versionText:SetAlpha(0.5)

  -- Options frame.
  frame.optionsFrame = Widgets:OptionsFrame({
    name = "$parent_OptionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.titleBackground, "BOTTOMLEFT", Widgets:Padding(), 0 },
      { "BOTTOMRIGHT", frame, "RIGHT", -Widgets:Padding(), Widgets:Padding(11) }
    },
    titleText = L.OPTIONS_TEXT
  })
  frame.optionsFrame:AddOption({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return SavedVariables:GetPerChar().characterSpecificSettings end,
    set = function() SavedVariables:Switch() end
  })
  frame.optionsFrame:AddOption({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return SavedVariables:Get().chatMessages end,
    set = function(value) SavedVariables:Get().chatMessages = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return SavedVariables:Get().itemTooltips end,
    set = function(value) SavedVariables:Get().itemTooltips = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.MERCHANT_BUTTON_TEXT,
    tooltipText = L.MERCHANT_BUTTON_TOOLTIP,
    get = function() return SavedVariables:Get().merchantButton end,
    set = function(value) SavedVariables:Get().merchantButton = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.MINIMAP_ICON_TEXT,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return not SavedVariables:Get().minimapIcon.hide end,
    set = function(value) SavedVariables:Get().minimapIcon.hide = not value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return SavedVariables:Get().autoRepair end,
    set = function(value) SavedVariables:Get().autoRepair = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return SavedVariables:Get().autoSell end,
    set = function(value) SavedVariables:Get().autoSell = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return SavedVariables:Get().safeMode end,
    set = function(value) SavedVariables:Get().safeMode = value end
  })
  frame.optionsFrame:AddOption({
    labelText = L.INCLUDE_POOR_ITEMS_TEXT,
    tooltipText = L.INCLUDE_POOR_ITEMS_TOOLTIP,
    get = function() return SavedVariables:Get().includePoorItems end,
    set = function(value) SavedVariables:Get().includePoorItems = value end
  })

  -- Inclusions frame.
  frame.inclusionsFrame = Widgets:ListFrame({
    name = "$parent_InclusionsFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.optionsFrame, "BOTTOMLEFT", 0, -Widgets:Padding(0.5) },
      { "BOTTOMRIGHT", frame, "BOTTOM", -Widgets:Padding(0.25), Widgets:Padding() }
    },
    titleText = Colors.Red(L.INCLUSIONS_TEXT),
    tooltipText = L.INCLUSIONS_DESCRIPTION,
    list = Addon.Lists.Inclusions
  })

  -- Exclusions frame.
  frame.exclusionsFrame = Widgets:ListFrame({
    name = "$parent_ExclusionsFrame",
    parent = frame,
    points = {
      { "TOPRIGHT", frame.optionsFrame, "BOTTOMRIGHT", 0, -Widgets:Padding(0.5) },
      { "BOTTOMLEFT", frame, "BOTTOM", Widgets:Padding(0.25), Widgets:Padding() }
    },
    titleText = Colors.Green(L.EXCLUSIONS_TEXT),
    tooltipText = L.EXCLUSIONS_DESCRIPTION,
    list = Addon.Lists.Exclusions
  })

  return frame
end)()
