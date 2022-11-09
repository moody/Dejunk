local ADDON_NAME, Addon = ...

Addon.VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
Addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Addon.IS_VANILLA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Addon.IS_WRATH = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
Addon.IS_CLASSIC = Addon.IS_VANILLA or Addon.IS_WRATH

-- ============================================================================
-- Tables
-- ============================================================================

-- Lists.
Addon.Lists = {
  Inclusions = {},
  Exclusions = {}
}

-- UserInterface.
Addon.UserInterface = {
  JunkFrame = {},
  TransportFrame = {},
  Widgets = {},
  Popup = {},
  MinimapIcon = {}
}

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
  local Confirmer = Addon:GetModule("Confirmer")
  local L = Addon:GetModule("Locale")
  local Seller = Addon:GetModule("Seller")

  function Addon:IsBusy()
    if Seller:IsBusy() then return true, L.IS_BUSY_SELLING_ITEMS end
    if self.Lists:IsBusy() then return true, L.IS_BUSY_UPDATING_LISTS end
    if Confirmer:IsBusy() then return true, L.IS_BUSY_CONFIRMING_ITEMS end
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
