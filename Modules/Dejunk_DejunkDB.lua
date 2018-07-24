-- DejunkDB: provides Dejunk modules easy access to saved variables.

local AddonName, Addon = ...

-- Dejunk
local DejunkDB = Addon.DejunkDB

-- ============================================================================
-- SV Table
-- ============================================================================

-- This table can be used to quickly get and set values in the
-- current SVs (global if DejunkPerChar.UseGlobal is true, per char if not).
DejunkDB.SV = setmetatable({}, {
  __index = function(t, k)
    if DejunkPerChar.UseGlobal then
      return DejunkGlobal[k]
    else
      return DejunkPerChar[k]
    end
  end,
  __newindex = function(t, k, v)
    if DejunkPerChar.UseGlobal then
      DejunkGlobal[k] = v
    else
      DejunkPerChar[k] = v
    end
  end
})

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
  DejunkPerChar.UseGlobal = not DejunkPerChar.UseGlobal
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

  -- Returns the value, table, and key for a specified key in a specified table.
  -- @param t - the table
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  -- @return 1 - the key value
  -- @return 2 - the table the key resides in
  -- @return 3 - the key
  local function get(t, k)
    if k:find(".") then
      for key in pairs(keys) do keys[key] = nil end
      -- Split keys by dot operator (e.g. "A.B.C" = {"A", "B", "C"})
      for key in k:gmatch("([^.]+)") do keys[#keys+1] = key end
      
      -- If key is nested, update ref to nested table and key
      if (#keys > 1) then
        for i=1, (#keys - 1) do t = t[keys[i]] end
        k = keys[#keys]
      end
    end

    return t[k], t, k
  end

  -- Sets the specified key in the global or per char SVs to the specified value.
  -- @param t - the table
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  -- @param v - the new value
  local function set(t, k, v)
    local _, nt, nk = get(t, k)
    nt[nk] = v
  end

  -- Returns the value of the specified key in the global SVs.
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  function DejunkDB:GetGlobal(k)
    local v = get(DejunkGlobal, k)
    return v
  end

  -- Returns the value of the specified key in the per character SVs.
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  function DejunkDB:GetPerChar(k)
    local v = get(DejunkPerChar, k)
    return v
  end

  -- Sets the specified key in the global SVs to the specified value.
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  -- @param v - the new value
  function DejunkDB:SetGlobal(k, v)
    set(DejunkGlobal, k, v)
  end

  -- Sets the specified key in the per character SVs to the specified value.
  -- @param k - the key, can be a nested value (e.g. "A.B.C")
  -- @param v - the new value
  function DejunkDB:SetPerChar(k, v)
    set(DejunkPerChar, k, v)
  end
end

-- Returns the value of the specified key in the current SVs.
-- @param k - the key, can be a nested value (e.g. "A.B.C")
function DejunkDB:Get(k)
  if DejunkPerChar.UseGlobal then
    return self:GetGlobal(k)
  else
    return self:GetPerChar(k)
  end
end

-- Sets the specified key in the current SVs to the specified value.
-- @param k - the key, can be a nested value (e.g. "A.B.C")
-- @param v - the new value
function DejunkDB:Set(k, v)
  if DejunkPerChar.UseGlobal then
    self:SetGlobal(k, v)
  else -- Use character settings
    self:SetPerChar(k, v)
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
    SellBelowAverageILVL = {
      Enabled = false,
      Value = 0
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
