local ADDON_NAME, Addon = ...

Addon.VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
Addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Addon.IS_VANILLA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Addon.IS_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Addon.IS_CLASSIC = Addon.IS_VANILLA or Addon.IS_WRATH

-- ============================================================================
-- Tables
-- ============================================================================

-- Libs.
Addon.Libs = {
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0")
}

-- Locale.
Addon.Locale = setmetatable({}, {
  __index = function(t, k)
    return rawget(t, k) or k
  end
})

-- Colors.
Addon.Colors = {}

-- Events.
Addon.Events = {}
Addon.EventManager = {}

-- SavedVariables.
Addon.SavedVariables = {}

-- Commands.
Addon.Commands = {}

-- Container.
Addon.Container = {}

-- Items.
Addon.Items = {}

-- Lists.
Addon.Lists = {
  Inclusions = {},
  Exclusions = {}
}

-- JunkFilter.
Addon.JunkFilter = {}

-- Seller.
Addon.Seller = {}

-- Destroyer.
Addon.Destroyer = {}

-- Confirmer.
Addon.Confirmer = {}

-- UserInterface.
Addon.UserInterface = {
  JunkFrame = {},
  TransportFrame = {},
  Widgets = {},
  Popup = {},
  MinimapIcon = {}
}

-- Tooltip.
Addon.Tooltip = {}

-- ============================================================================
-- Functions
-- ============================================================================

function Addon:IfNil(value, default)
  if value == nil then return default end
  return value
end

function Addon:IsBusy()
  if self.Seller:IsBusy() then return true, self.Locale.IS_BUSY_SELLING_ITEMS end
  if self.Lists:IsBusy() then return true, self.Locale.IS_BUSY_UPDATING_LISTS end
  if self.Confirmer:IsBusy() then return true, self.Locale.IS_BUSY_CONFIRMING_ITEMS end
  return false
end

function Addon:ForcePrint(...)
  print(self.Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
end

function Addon:Print(...)
  if self.SavedVariables:Get().chatMessages then
    print(self.Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
  end
end

function Addon:Debug(...)
  print(self.Colors.Red("[Debug]"), ...)
end
