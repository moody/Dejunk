local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables
local Seller = Addon.Seller
local UserInterface = Addon.UserInterface
local Widgets = Addon.UserInterface.Widgets

local function isBusy()
  if Seller:IsBusy() then return true, L.IS_BUSY_SELLING_ITEMS end
  if Lists:IsBusy() then return true, L.IS_BUSY_UPDATING_LISTS end
  return false
end

local function initialize()
  local parentFrame = Widgets:Window({
    name = ADDON_NAME .. "_ParentFrame",
    parent = UIParent,
    points = { { "CENTER" } },
    width = 650,
    height = 500,
    titleText = Colors.Blue(ADDON_NAME),
  })
  table.insert(UISpecialFrames, parentFrame:GetName())

  -- Busy text.
  parentFrame.busyText = parentFrame:CreateFontString("$parent_BusyText", "ARTWORK", "GameFont_Gigantic")
  parentFrame.busyText:SetPoint("CENTER")
  parentFrame.busyText:SetAlpha(0.5)
  parentFrame.busyText:Hide()

  parentFrame:HookScript("OnUpdate", function(self)
    local busy, reason = isBusy()
    if busy then
      self.busyText:SetText(Colors.White(reason))
      self.busyText:Show()
      self.optionsFrame:Hide()
      self.inclusionsFrame:Hide()
      self.exclusionsFrame:Hide()
    else
      self.busyText:Hide()
      self.optionsFrame:Show()
      self.inclusionsFrame:Show()
      self.exclusionsFrame:Show()
    end
  end)

  -- Options frame.
  parentFrame.optionsFrame = Widgets:OptionsFrame({
    name = "$parent_OptionsFrame",
    parent = parentFrame,
    points = {
      { "TOPLEFT", parentFrame.title, "BOTTOMLEFT", 0, -Widgets:Padding() },
      { "BOTTOMRIGHT", parentFrame, "RIGHT", -Widgets:Padding(), Widgets:Padding(12) }
    },
    titleText = L.OPTIONS_TEXT
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.CHARACTER_SPECIFIC_SETTINGS_TEXT,
    tooltipText = L.CHARACTER_SPECIFIC_SETTINGS_TOOLTIP,
    get = function() return SavedVariables:GetPerChar().characterSpecificSettings end,
    set = function() SavedVariables:Switch() end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.CHAT_MESSAGES_TEXT,
    tooltipText = L.CHAT_MESSAGES_TOOLTIP,
    get = function() return SavedVariables:Get().chatMessages end,
    set = function(value) SavedVariables:Get().chatMessages = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.BAG_ITEM_TOOLTIPS_TEXT,
    tooltipText = L.BAG_ITEM_TOOLTIPS_TOOLTIP,
    get = function() return SavedVariables:Get().itemTooltips end,
    set = function(value) SavedVariables:Get().itemTooltips = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.MERCHANT_BUTTON_TEXT,
    tooltipText = L.MERCHANT_BUTTON_TOOLTIP,
    get = function() return SavedVariables:Get().merchantButton end,
    set = function(value) SavedVariables:Get().merchantButton = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.MINIMAP_ICON_TEXT,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return not SavedVariables:Get().minimapIcon.hide end,
    set = function(value) SavedVariables:Get().minimapIcon.hide = not value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.AUTO_REPAIR_TEXT,
    tooltipText = L.AUTO_REPAIR_TOOLTIP,
    get = function() return SavedVariables:Get().autoRepair end,
    set = function(value) SavedVariables:Get().autoRepair = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.AUTO_SELL_TEXT,
    tooltipText = L.AUTO_SELL_TOOLTIP,
    get = function() return SavedVariables:Get().autoSell end,
    set = function(value) SavedVariables:Get().autoSell = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.SAFE_MODE_TEXT,
    tooltipText = L.SAFE_MODE_TOOLTIP,
    get = function() return SavedVariables:Get().safeMode end,
    set = function(value) SavedVariables:Get().safeMode = value end
  })
  parentFrame.optionsFrame:AddOption({
    labelText = L.INCLUDE_POOR_ITEMS_TEXT,
    tooltipText = L.INCLUDE_POOR_ITEMS_TOOLTIP,
    get = function() return SavedVariables:Get().includePoorItems end,
    set = function(value) SavedVariables:Get().includePoorItems = value end
  })

  -- Inclusions frame.
  parentFrame.inclusionsFrame = Widgets:ListFrame({
    name = "$parent_InclusionsFrame",
    parent = parentFrame,
    points = {
      { "TOPLEFT", parentFrame.optionsFrame, "BOTTOMLEFT", 0, -Widgets:Padding(0.5) },
      { "BOTTOMRIGHT", parentFrame, "BOTTOM", -Widgets:Padding(0.25), Widgets:Padding() }
    },
    titleText = Colors.Red(L.INCLUSIONS_TEXT),
    descriptionText = L.INCLUSIONS_DESCRIPTION,
    list = Addon.Lists.Inclusions
  })

  -- Exclusions frame.
  parentFrame.exclusionsFrame = Widgets:ListFrame({
    name = "$parent_ExclusionsFrame",
    parent = parentFrame,
    points = {
      { "TOPRIGHT", parentFrame.optionsFrame, "BOTTOMRIGHT", 0, -Widgets:Padding(0.5) },
      { "BOTTOMLEFT", parentFrame, "BOTTOM", Widgets:Padding(0.25), Widgets:Padding() }
    },
    titleText = Colors.Green(L.EXCLUSIONS_TEXT),
    descriptionText = L.EXCLUSIONS_DESCRIPTION,
    list = Addon.Lists.Exclusions
  })

  -- Add parentFrame to UserInterface.
  UserInterface.parentFrame = parentFrame
end

function UserInterface:Show()
  if not self.parentFrame then initialize() end
  self.parentFrame:Show()
end

function UserInterface:Hide()
  if self.parentFrame then self.parentFrame:Hide() end
end

function UserInterface:Toggle()
  if not self.parentFrame then
    self:Show()
  else
    if self.parentFrame:IsShown() then
      self.parentFrame:Hide()
    else
      self.parentFrame:Show()
    end
  end
end

-- C_Timer.After(0.1, function() UserInterface:Show() end)
