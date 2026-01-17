local ADDON_NAME = ... ---@type string

--- @class Addon
--- @field Wux Wux
local Addon = select(2, ...)

-- ============================================================================
-- Addon - Constants
-- ============================================================================

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
Addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
Addon.IS_VANILLA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Addon.IS_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Addon.IS_CATA = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
Addon.IS_MISTS = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

-- ============================================================================
-- Addon - Methods
-- ============================================================================

-- Addon:GetModule()
do
  --- @type table<string, table>
  local modules = {}

  --- Gets or creates a module table for the given `key`.
  --- @generic T
  --- @param key `T`
  --- @return T
  function Addon:GetModule(key)
    --- @cast key +string
    key = key:upper()
    if type(modules[key]) ~= "table" then modules[key] = {} end
    return modules[key]
  end
end

-- Addon:GetLibrary()
do
  --- @enum (key) LibraryKey
  local libraries = {
    LDB = LibStub("LibDataBroker-1.1"),
    LDBIcon = LibStub("LibDBIcon-1.0")
  }

  --- Returns a library based on the given `key`.
  --- @param key LibraryKey
  --- @return table
  function Addon:GetLibrary(key)
    return libraries[key] or error("Invalid library: " .. key)
  end
end

--- Returns the full path to a file in the `/assets` folder.
--- @param fileName string
--- @return string
function Addon:GetAsset(fileName)
  return ("Interface\\AddOns\\%s\\assets\\%s"):format(ADDON_NAME, fileName)
end

--- Returns the current highest latency value in seconds.
--- @param minLatency? number
--- @return number latency value will always be `>= 0.2` seconds
function Addon:GetLatency(minLatency)
  local _, _, home, world = GetNetStats()
  local latency = max(home, world) * 0.001
  return max(latency, minLatency or 0.2)
end

-- Addon:Concat(), Addon:SubjectDescription()
do
  local Colors = Addon:GetModule("Colors")
  local cache = {}

  --- Concatenates arguments with a given separator.
  --- @param sep string
  --- @param ... string|number
  --- @return string
  function Addon:Concat(sep, ...)
    for k in pairs(cache) do cache[k] = nil end
    for i = 1, select("#", ...) do cache[#cache + 1] = select(i, ...) end
    return table.concat(cache, Colors.Grey(sep))
  end

  --- Combines a `subject` and `description` into a formatted string (e.g., `"- <subject>: <description>"`).
  --- @param subject string
  --- @param description string
  --- @return string
  function Addon:SubjectDescription(subject, description)
    return Colors.Grey("- %s: %s"):format(Colors.Gold(subject), Colors.White(description))
  end
end

--- Returns `value` if it is not nil; otherwise, returns `default`.
--- @generic T1, T2
--- @param value? T1
--- @param default T2
--- @return T1|T2 value
function Addon:IfNil(value, default)
  if value == nil then return default end
  return value
end

-- Addon:IsBusy()
do
  local Confirmer = Addon:GetModule("Confirmer")
  local L = Addon:GetModule("Locale")
  local Seller = Addon:GetModule("Seller")

  --- Returns `true` with a reason string if a critical process is active.
  --- @return boolean isBusy
  --- @return string? reason
  function Addon:IsBusy()
    if Seller:IsBusy() then return true, L.IS_BUSY_SELLING_ITEMS end
    if Confirmer:IsBusy() then return true, L.IS_BUSY_CONFIRMING_ITEMS end
    return false
  end
end

--- Returns `true` if the player is interacting with a merchant.
--- @return boolean
function Addon:IsAtMerchant()
  return (MerchantFrame and MerchantFrame:IsShown()) or false
end

-- Addon:ForcePrint(), Addon:Print(), Addon:Debug()
do
  local Colors = Addon:GetModule("Colors")
  local StateManager = Addon:GetModule("StateManager")

  --- Forcefully prints the given arguments.
  --- @param ... any
  function Addon:ForcePrint(...)
    print(Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
  end

  --- Prints the given arguments if chat messages are enabled.
  --- @param ... any
  function Addon:Print(...)
    if StateManager:GetGlobalState().chatMessages then
      print(Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
    end
  end

  --- Prints the given arguments with debug formatting.
  --- @param ... any
  function Addon:Debug(...)
    --@debug@
    print(date("%H:%M:%S"), Colors.Red("[Debug]"), ...)
    --@end-debug@
  end
end
