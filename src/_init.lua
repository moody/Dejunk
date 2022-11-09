local ADDON_NAME, Addon = ...

Addon.VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
Addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Addon.IS_VANILLA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Addon.IS_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Addon.IS_CLASSIC = Addon.IS_VANILLA or Addon.IS_WRATH

-- ============================================================================
-- Tables
-- ============================================================================

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

do -- Addon:GetModule()
  local modules = {}

  function Addon:GetModule(key)
    if type(modules[key]) ~= "table" then modules[key] = {} end
    return modules[key]
  end
end

do -- Addon:GetLibrary()
  local libraries = {
    LDB = LibStub("LibDataBroker-1.1"),
    LDBIcon = LibStub("LibDBIcon-1.0")
  }

  function Addon:GetLibrary(key)
    return libraries[key] or error("Invalid library: " .. key)
  end
end

function Addon:IfNil(value, default)
  if value == nil then return default end
  return value
end

do -- Addon:IsBusy()
  local L = Addon:GetModule("Locale")

  function Addon:IsBusy()
    if self.Seller:IsBusy() then return true, L.IS_BUSY_SELLING_ITEMS end
    if self.Lists:IsBusy() then return true, L.IS_BUSY_UPDATING_LISTS end
    if self.Confirmer:IsBusy() then return true, L.IS_BUSY_CONFIRMING_ITEMS end
    return false
  end
end

do -- Addon:ForcePrint(), Addon:Print(), Addon:Debug()
  local Colors = Addon:GetModule("Colors")
  local SavedVariables = Addon:GetModule("SavedVariables")

  function Addon:ForcePrint(...)
    print(Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
  end

  function Addon:Print(...)
    if SavedVariables:Get().chatMessages then
      print(Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
    end
  end

  function Addon:Debug(...)
    print(Colors.Red("[Debug]"), ...)
  end
end
