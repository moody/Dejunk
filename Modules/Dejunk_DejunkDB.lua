-- Dejunk_DejunkDB: provides Dejunk modules easy access to saved variables.

local AddonName, DJ = ...

-- Dejunk
local DejunkDB = DJ.DejunkDB

-- Variables
DejunkDB.Initialized = false
DejunkDB.SV = nil

-- ============================================================================
--                             Database Functions
-- ============================================================================

-- Initializes the database.
function DejunkDB:Initialize()
  if self.Initialized then return end
  self.Initialized = true

  self:FormatGlobalSettings()
  self:FormatPerCharSettings()
  self:FormatLists()

  self:Update()
end

-- Updates the Database's reference to the saved variables.
function DejunkDB:Update()
  if DejunkPerChar.UseGlobal then
    self.SV = DejunkGlobal
  else -- Use character settings
    self.SV = DejunkPerChar
  end
end

-- ============================================================================
--                              Format Functions
-- ============================================================================

-- Adds default values to the global settings and removes deprecated values.
function DejunkDB:FormatGlobalSettings()
  local newSettings = self:GetDefaultGlobalSettings()

  if (DejunkGlobal == nil) then
    DejunkGlobal = newSettings
    return
  end

  -- Add missing global values
  for k, v in pairs(newSettings) do
    if (DejunkGlobal[k] == nil) then
      DejunkGlobal[k] = v end
  end

  -- Remove deprecated global values
  for k, v in pairs(DejunkGlobal) do
    if (newSettings[k] == nil) then
      DejunkGlobal[k] = nil end
  end
end

-- Adds default values to the per character settings and removes deprecated values.
function DejunkDB:FormatPerCharSettings()
  local newSettings = self:GetDefaultPerCharSettings()

  if (DejunkPerChar == nil) then
    DejunkPerChar = newSettings
    return
  end

  -- Add missing PerChar values
  for k, v in pairs(newSettings) do
    if (DejunkPerChar[k] == nil) then
      DejunkPerChar[k] = v end
  end

  -- Remove deprecated PerChar values
  for k, v in pairs(DejunkPerChar) do
    if (newSettings[k] == nil) then
      DejunkPerChar[k] = nil end
  end
end

-- Converts legacy item lists to the newest format.
function DejunkDB:FormatLists()
  local convert = function(list)
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
--                             Settings Functions
-- ============================================================================

-- Returns the base default saved variables.
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
    DestroyToysAlreadyKnown = false,
    DestroyIgnoreExclusions = false,

    -- Lists, table of itemIDs: { ["itemID"] = true }
    Inclusions = {},
    Exclusions = {},
    Destroyables = {}
  }
end

-- Returns the default global saved variables.
function DejunkDB:GetDefaultGlobalSettings()
  local settings = self:Defaults()

  -- Add
  settings.ColorScheme = "Default"
  settings.Minimap = { hide = false }
  settings.ItemTooltip = true

  return settings
end

-- Returns the default per character saved variables.
function DejunkDB:GetDefaultPerCharSettings()
  local settings = self:Defaults()

  -- Add
  settings.UseGlobal = true

  return settings
end

-- Add default key strings to DejunkDB
local keys = DejunkDB:Defaults()
for k in pairs(keys) do DejunkDB[k] = k end
keys = nil
