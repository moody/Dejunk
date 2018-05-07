-- Dejunk_DejunkDB: provides Dejunk modules easy access to saved variables.

local AddonName, Addon = ...

-- Dejunk
local DejunkDB = Addon.DejunkDB

--[[
  This table (DejunkDB.SV) can be used to quickly get and set values in the
  current SVs (global if DejunkPerChar.UseGlobal is true, per char if not).

  There is a downside to using this table to set values: it will not notify
  any registed listeners that a change has occurred. This is by design so that
  there is no confusion as to why no notification happens when setting a nested
  table value.
  
  If notifying is necessary, call DejunkDB:Set(k, v) manually.
--]]
DejunkDB.SV = setmetatable({}, {
  __index = function(t, k)
    return DejunkPerChar.UseGlobal and DejunkGlobal[k] or DejunkPerChar[k]
  end,
  __newindex = function(t, k, v)
    if DejunkPerChar.UseGlobal then
      DejunkGlobal[k] = v
    else
      DejunkPerChar[k] = v
    end
  end
})

-- Listeners
local listeners = {}

-- Notifies listener functions that a saved variable change has occurred.
-- @param g - true if the change was global, false if per character
-- @param k - the key that was changed
-- @param v - the new value
-- @param o - the old value
local function notifyListeners(g, k, v, o)
  for listener in pairs(listeners) do listener(g, k, v, o) end
end

-- ============================================================================
-- Database Functions
-- ============================================================================

-- Initializes the database.
function DejunkDB:Initialize()
  self:FormatGlobalSettings()
  self:FormatPerCharSettings()
  self:FormatLists()

  self.Initialize = nil
  self.FormatGlobalSettings = nil
  self.FormatPerCharSettings = nil
  self.FormatLists = nil
end

-- Toggles between global and per char SVs.
function DejunkDB:Toggle()
  local o = DejunkPerChar.UseGlobal
  local v = not o
  DejunkPerChar.UseGlobal = v
  notifyListeners("UseGlobal", v, o, false)
end

-- Adds a listener to be notified upon changes to SVs.
function DejunkDB:AddListener(func)
  assert(type(func) == "function", "func must be a function")
  assert(not listeners[func], "attempt to add existing listener")
  listeners[func] = true
end

-- ============================================================================
-- Getters & Setters
-- ============================================================================

do
  local keys = {
    -- [1] = a nested table
    -- ...
    -- [n] = key in nested table
  }

  -- Returns the nested value, table, and key in the global or per char SVs.
  -- @param g - if true, global SVs are used, otherwise per character
  -- @param k - the key, can be a nested value (e.g. "DestroyPriceThreshold.Gold")
  local function get_nested(g, k)
    local nt = g and DejunkGlobal or DejunkPerChar
    local nk = k
    
    if k:find(".") then
      for k in pairs(keys) do keys[k] = nil end
      -- Split keys by dot operator (e.g. "A.B.C" = {"A", "B", "C"})
      for key in k:gmatch("([^.]+)") do keys[#keys+1] = key end
      
      -- If key is nested, update ref to nested table and key
      if (#keys > 1) then
        nt = nt[keys[1]]
        for i=2, (#keys - 1) do nt = nt[keys[i]] end
        nk = keys[#keys]
      end
    end

    return nt[nk], nt, nk
  end

  -- Sets the specified key in the global or per char SVs to the specified value.
  -- @param g - if true, global SVs are used, otherwise per character
  -- @param k - the key, can be a nested value (e.g. "DestroyPriceThreshold.Gold")
  -- @param v - the new value
  -- @param silent - if true, listeners will not be notified [optional]
  local function set(g, k, v, silent)
    local o, nt, nk = get_nested(g, k)
    nt[nk] = v
    if not silent then notifyListeners(g, k, v, o) end
  end

  -- Returns the value of the specified key in the global SVs.
  -- @param k - the key
  function DejunkDB:GetGlobal(k)
    local v = get_nested(true, k)
    return v
  end

  -- Returns the value of the specified key in the per character SVs.
  -- @param k - the key
  function DejunkDB:GetPerChar(k)
    local v = get_nested(false, k)
    return v
  end

  -- Sets the specified key in the global SVs to the specified value.
  -- @param k - the key, can be a nested value (e.g. "DestroyPriceThreshold.Gold")
  -- @param v - the new value
  -- @param silent - if true, listeners will not be notified [optional]
  function DejunkDB:SetGlobal(k, v, silent)
    set(true, k, v, silent)
  end

  -- Sets the specified key in the per character SVs to the specified value.
  -- @param k - the key, can be a nested value (e.g. "DestroyPriceThreshold.Gold")
  -- @param v - the new value
  -- @param silent - if true, listeners will not be notified [optional]
  function DejunkDB:SetPerChar(k, v, silent)
    set(false, k, v, silent)
  end
end

-- Returns the value of the specified key in the current SVs.
-- @param k - the key
function DejunkDB:Get(k)
  return DejunkPerChar.UseGlobal and self:GetGlobal(k) or self:GetPerChar(k)
end

-- Sets the specified key in the current SVs to the specified value.
-- @param k - the key, can be a nested value (e.g. "DestroyPriceThreshold.Gold")
-- @param v - the new value
-- @param silent - if true, listeners will not be notified [optional]
function DejunkDB:Set(k, v, silent)
  if DejunkPerChar.UseGlobal then
    self:SetGlobal(k, v, silent)
  else -- Use character settings
    self:SetPerChar(k, v, silent)
  end
end

-- ============================================================================
-- Format Functions
-- ============================================================================

-- Adds default values to the global settings and removes deprecated values.
function DejunkDB:FormatGlobalSettings()
  local newSettings = self:GetDefaultGlobalSettings()

  -- Set and return if global SVs don't exist
  if (DejunkGlobal == nil) then
    DejunkGlobal = newSettings
    return
  end

  -- Add missing global values
  for k, v in pairs(newSettings) do
    if (DejunkGlobal[k] == nil) then DejunkGlobal[k] = v end
  end

  -- Remove deprecated global values
  for k, v in pairs(DejunkGlobal) do
    if (newSettings[k] == nil) then DejunkGlobal[k] = nil end
  end
end

-- Adds default values to the per character settings and removes deprecated values.
function DejunkDB:FormatPerCharSettings()
  local newSettings = self:GetDefaultPerCharSettings()

  -- Set and return if per char SVs don't exist
  if (DejunkPerChar == nil) then
    DejunkPerChar = newSettings
    return
  end

  -- Add missing per char values
  for k, v in pairs(newSettings) do
    if (DejunkPerChar[k] == nil) then DejunkPerChar[k] = v end
  end

  -- Remove deprecated per char values
  for k, v in pairs(DejunkPerChar) do
    if (newSettings[k] == nil) then DejunkPerChar[k] = nil end
  end
end

-- Converts legacy item lists to the newest format.
function DejunkDB:FormatLists()
  local function convert(list)
    local newEntries = {}

    for k, v in pairs(list) do
      if (type(v) == "table" and v.ItemID) then
        local itemID = tostring(v.ItemID)
        newEntries[itemID] = true
        list[k] = nil
      end
    end

    for k in pairs(newEntries) do
      list[k] = true
    end
  end

  -- Perform conversions
  for k, v in pairs({DejunkGlobal, DejunkPerChar}) do
    convert(v.Inclusions)
    convert(v.Exclusions)
  end
end

-- ============================================================================
-- Settings Functions
-- ============================================================================

-- Returns the base default SVs.
function DejunkDB:Defaults()
	return
	{
    -- General options
    SilentMode = false,
    VerboseMode = false,
    AutoSell = false,
    SafeMode = true,
    AutoRepair = false,
    UseGuildRepair = true,

    -- Sell options
    SellPoor = true,
    SellCommon = false,
    SellUncommon = false,
    SellRare = false,
    SellEpic = false,

    SellUnsuitable = false,
    SellEquipmentBelowILVL = {
      Enabled = false,
      Value = 1,
    },

    -- Ignore options
    IgnoreBattlePets = false,
    IgnoreConsumables = false,
    IgnoreGems = false,
    IgnoreGlyphs = false,
    IgnoreItemEnhancements = false,
    IgnoreRecipes = false,
    IgnoreTradeGoods = false,
    IgnoreCosmetic = false,
    IgnoreBindsWhenEquipped = false,
    IgnoreSoulbound = false,
    IgnoreEquipmentSets = false,
    IgnoreTradeable = false,

    -- Destroy options
    AutoDestroy = false,
    DestroyUsePriceThreshold = false,
    DestroyPriceThreshold = {
      Gold = 0,
      Silver = 0,
      Copper = 0
    },
    DestroyPoor = false,
    DestroyInclusions = false,
    DestroyPetsAlreadyCollected = false,
    DestroyToysAlreadyCollected = false,
    DestroyIgnoreExclusions = false,

    -- Lists, table of itemIDs: { ["itemID"] = true }
    Inclusions = {},
    Exclusions = {},
    Destroyables = {}
  }
end

-- Returns the default global SVs.
function DejunkDB:GetDefaultGlobalSettings()
  local settings = self:Defaults()

  -- Add
  settings.ColorScheme = "Default"
  settings.Minimap = { hide = false }
  settings.ItemTooltip = true

  return settings
end

-- Returns the default per character SVs.
function DejunkDB:GetDefaultPerCharSettings()
  local settings = self:Defaults()

  -- Add
  settings.UseGlobal = true

  return settings
end
