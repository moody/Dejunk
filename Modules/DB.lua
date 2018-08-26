-- DB: provides addon modules easy access to saved variables.

local AddonName, Addon = ...

-- Addon
local DB = Addon.DB
local Consts = Addon.Consts

-- Default database values
local defaults = {
  Global = {
    ColorScheme = 1,
    Minimap = { hide = false },
    ItemTooltip = true
  },
  Profile = {
    -- General options
    SilentMode = false,
    VerboseMode = true,
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
      Value = Consts.BELOW_AVERAGE_ILVL_MIN
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
}

-- ============================================================================
-- Database Functions
-- ============================================================================

-- Converts the old version of the DB into the new one.
local function reformat()
  local globalProfile = DEJUNK_ADDON_SV.Profiles.Global
  local useGlobal = false -- for DejunkPerChar.UseGlobal

  -- If DejunkGlobal has old values, move them to the global profile
  if DejunkGlobal then
    for k, v in pairs(DejunkGlobal) do
      if (defaults.Global[k] ~= nil) then
        DB.Global[k] = v -- Move the value to Global
      elseif (defaults.Profile[k] ~= nil) then
        globalProfile[k] = v -- Move the value to the Global profile
      end
    end
    -- Delete table
    DejunkGlobal = nil
  end

  -- Move DejunkPerChar values to the player profile
  -- The profile will be for the current player if DejunkPerChar exists
  if DejunkPerChar then
    for k, v in pairs(DejunkPerChar) do
      if (defaults.Profile[k] ~= nil) then
        DB.Profile[k] = v -- Move the value to Profile
      end
    end
    -- Cache UseGlobal
    useGlobal = DejunkPerChar.UseGlobal
    -- Delete table
    DejunkPerChar = nil
  end

  -- Clamp min-max value variables
  globalProfile.SellBelowAverageILVL.Value = Clamp(
    globalProfile.SellBelowAverageILVL.Value,
    Consts.BELOW_AVERAGE_ILVL_MIN,
    Consts.BELOW_AVERAGE_ILVL_MAX
  )
  DB.Profile.SellBelowAverageILVL.Value = Clamp(
    DB.Profile.SellBelowAverageILVL.Value,
    Consts.BELOW_AVERAGE_ILVL_MIN,
    Consts.BELOW_AVERAGE_ILVL_MAX
  )

  -- Set profile to Global if DejunkerPerChar.UseGlobal was true
  if useGlobal then DB:SetProfile("Global") end
end

-- Initializes the database.
function DB:Initialize()
  self.Initialize = nil
  local db = DethsLibLoader("DethsDBLib", "1.0"):Create(AddonName, defaults)
  setmetatable(self, {__index = db})
  if not db:ProfileExists("Global") then db:CreateProfile("Global") end
  reformat()
end
