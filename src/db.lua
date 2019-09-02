-- DB: provides addon modules easy access to saved variables.

local AddonName, Addon = ...
local Clamp = _G.Clamp
local Consts = Addon.Consts
local DB = Addon.DB

-- Default database values
local defaults = {
  Global = {
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
    IgnoreReadable = false,
    IgnoreTradeable = false,

    -- Destroy options
    AutoDestroy = false,
    DestroyBelowPrice = {
      Enabled = false,
      Value = Consts.DESTROY_BELOW_PRICE_MIN
    },
    DestroyPoor = false,
    DestroyInclusions = false,
    DestroyPetsAlreadyCollected = false,
    DestroyToysAlreadyCollected = false,
    DestroyIgnoreExclusions = false,
    DestroyIgnoreReadable = false,

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
  local globalProfile = _G.DEJUNK_ADDON_SV.Profiles.Global
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

  -- Iterate all profiles
  for _, profile in pairs(_G.DEJUNK_ADDON_SV.Profiles) do
    profile.DestroyUsePriceThreshold = nil
    profile.DestroyPriceThreshold = nil

    -- Clamp min-max value variables
    profile.SellBelowAverageILVL.Value = Clamp(
      profile.SellBelowAverageILVL.Value,
      Consts.BELOW_AVERAGE_ILVL_MIN,
      Consts.BELOW_AVERAGE_ILVL_MAX
    )

    profile.DestroyBelowPrice.Value = Clamp(
      profile.DestroyBelowPrice.Value,
      Consts.DESTROY_BELOW_PRICE_MIN,
      Consts.DESTROY_BELOW_PRICE_MAX
    )
  end

  -- Set profile to Global if DejunkerPerChar.UseGlobal was true
  if useGlobal then DB:SetProfile("Global") end
end

-- Initializes the database.
function DB:Initialize()
  self.Initialize = nil
  local db = Addon.DethsDBLib(AddonName, defaults)
  setmetatable(self, {__index = db})
  if not db:ProfileExists("Global") then db:CreateProfile("Global") end
  reformat()
end
