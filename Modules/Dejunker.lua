-- Dejunker: handles the process of selling junk items to merchants.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL
local DCL = Addon.Libs.DCL
local DTL = Addon.Libs.DTL

-- Upvalues
local assert, floor, format, max, tremove =
      assert, floor, format, max, table.remove

local ERR_INTERNAL_BAG_ERROR, ERR_VENDOR_DOESNT_BUY =
      ERR_INTERNAL_BAG_ERROR, ERR_VENDOR_DOESNT_BUY

local LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_COMMON, LE_ITEM_QUALITY_UNCOMMON =
      LE_ITEM_QUALITY_POOR, LE_ITEM_QUALITY_COMMON, LE_ITEM_QUALITY_UNCOMMON
local LE_ITEM_QUALITY_RARE, LE_ITEM_QUALITY_EPIC =
      LE_ITEM_QUALITY_RARE, LE_ITEM_QUALITY_EPIC
local LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_COSMETIC =
      LE_ITEM_ARMOR_GENERIC, LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_WEAPON_GENERIC, LE_ITEM_WEAPON_FISHINGPOLE =
      LE_ITEM_WEAPON_GENERIC, LE_ITEM_WEAPON_FISHINGPOLE

local UseContainerItem = UseContainerItem

-- Modules
local Dejunker = Addon.Dejunker
local Confirmer = Addon.Confirmer

local Core = Addon.Core
local Consts = Addon.Consts
local DB = Addon.DB
local ListManager = Addon.ListManager
local Tools = Addon.Tools

-- Variables
local states = {
  None = 0,
  Dejunking = 1,
  Selling = 2
}
local currentState = states.None

local itemsToSell = {}

-- Event handler.
function Dejunker:OnEvent(event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if self:IsDejunking() then
      if (msg == ERR_INTERNAL_BAG_ERROR) then
        UIErrorsFrame:Clear()
      elseif (msg == ERR_VENDOR_DOESNT_BUY) then
        UIErrorsFrame:Clear()
        Core:Print(L.VENDOR_DOESNT_BUY)
        self:StopDejunking()
      end
    end
  end
end

-- ============================================================================
-- Dejunking Functions
-- ============================================================================

do
  -- Starts the Dejunking process.
  -- @param auto - if the process was started automatically
  function Dejunker:StartDejunking(auto)
    local canDejunk, msg = Core:CanDejunk()
    if not canDejunk then
      if not auto then Core:Print(msg) end
      return
    end

    Confirmer:Start("Dejunker")
    currentState = states.Dejunking
    self.incompleteTooltips = false

    -- Get junk items
    local maxItems = DB.Profile.SafeMode and Consts.SAFE_MODE_MAX
    DBL:GetItemsByFilter(Dejunker.Filter, itemsToSell, maxItems)
    local upToDate = DBL:IsUpToDate()

    -- Notify if tooltips could not be scanned
    if self.incompleteTooltips then
      self.incompleteTooltips = false
      Core:Print(L.IGNORING_ITEMS_INCOMPLETE_TOOLTIPS)
    end

    -- Stop if no items
    if (#itemsToSell == 0) then
      if not auto then
        Core:Print(upToDate and L.NO_JUNK_ITEMS or L.NO_CACHED_JUNK_ITEMS)
      end
      self:StopDejunking()
      return
    end

    -- If DBL isn't up to date, we'll only have items that are cached
    if not upToDate then Core:Print(L.ONLY_SELLING_CACHED) end

    -- Print safe mode message if necessary
    if DB.Profile.SafeMode and (#itemsToSell == Consts.SAFE_MODE_MAX) then
      Core:Print(format(L.SAFE_MODE_MESSAGE, Consts.SAFE_MODE_MAX))
    end

    self:StartSelling()
  end

  -- Cancels the Dejunking process.
  function Dejunker:StopDejunking()
    assert(currentState ~= states.None)
    self.OnUpdate = nil
    Confirmer:Stop("Dejunker")
    currentState = states.None
  end

  -- Checks whether or not the Dejunker is active.
  -- @return - boolean
  function Dejunker:IsDejunking()
    return (currentState ~= states.None) or Confirmer:IsConfirming("Dejunker")
  end
end

-- ============================================================================
-- Selling Functions
-- ============================================================================

do
  local interval = 0

  -- Selling update function
  local function sellItems_OnUpdate(self, elapsed)
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0

      -- Get next item
      local item = tremove(itemsToSell)
      -- Stop if there are no more items
      if not item then Dejunker:StopSelling() return end
      -- Otherwise, verify that the item in the bag slot has not been changed before selling
      if not DBL:StillInBags(item) or item:IsLocked() then
        DBL:Release(item)
        return
      end
      -- Sell item
      UseContainerItem(item.Bag, item.Slot)
      -- Notify confirmer
      Confirmer:Queue("Dejunker", item)
    end
  end

  -- Starts the selling process.
  function Dejunker:StartSelling()
    assert(currentState == states.Dejunking)
    assert(#itemsToSell > 0)
    currentState = states.Selling
    interval = 0
    self.OnUpdate = sellItems_OnUpdate
  end

  -- Cancels the selling process and stops dejunking.
  function Dejunker:StopSelling()
    assert(currentState == states.Selling)
    self.OnUpdate = nil
    self:StopDejunking()
  end

  -- Checks whether or not the Dejunker is actively selling items.
  -- @return - boolean
  function Dejunker:IsSelling()
    return (currentState == states.Selling)
  end
end

-- ============================================================================
-- Filter Functions
-- ============================================================================

-- Returns true if the specified item is dejunkable.
-- @param item - the item to run through the filter
Dejunker.Filter = function(item)
  if -- Ignore item if it is locked, refundable, or not sellable
    item:IsLocked() or
    Tools:ItemCanBeRefunded(item) or
    item.NoValue or
    not Tools:ItemCanBeSold(item)
  then
    -- Core:Debug("Dejunker", "Filtered out "..item.ItemLink)
    return false
  end

  local isJunkItem = Dejunker:IsJunkItem(item)
  return isJunkItem
end

-- Returns a boolean value and a reason string based on whether or not Dejunk
-- will sell the item.
-- @param item - a DethsBagLib item
function Dejunker:IsJunkItem(item)
  --[[ Priority
  1. Is it excluded?
  2. Is it included?
  3. Custom checks
  4. Is it a sell by quality item?
  ]]

  -- 1
  if ListManager:IsOnList("Exclusions", item.ItemID) then
    return false, format(L.REASON_ITEM_ON_LIST_TEXT, L.EXCLUSIONS_TEXT)
  end

  -- 2
  if ListManager:IsOnList("Inclusions", item.ItemID) then
    return true, format(L.REASON_ITEM_ON_LIST_TEXT, L.INCLUSIONS_TEXT)
  end
  
  -- 3

  -- Ignore by category
  if self:IsIgnoredBattlePetItem(item) then
    return false, L.REASON_IGNORE_BATTLEPETS_TEXT end
  if self:IsIgnoredConsumableItem(item) then
    return false, L.REASON_IGNORE_CONSUMABLES_TEXT end
  if self:IsIgnoredGemItem(item) then
    return false, L.REASON_IGNORE_GEMS_TEXT end
  if self:IsIgnoredGlyphItem(item) then
    return false, L.REASON_IGNORE_GLYPHS_TEXT end
  if self:IsIgnoredItemEnhancementItem(item) then
    return false, L.REASON_IGNORE_ITEM_ENHANCEMENTS_TEXT end
  if self:IsIgnoredRecipeItem(item) then
    return false, L.REASON_IGNORE_RECIPES_TEXT end
  if self:IsIgnoredTradeGoodsItem(item) then
    return false, L.REASON_IGNORE_TRADE_GOODS_TEXT end

  -- Ignore by type
  if self:IsIgnoredCosmeticItem(item) then
    return false, L.REASON_IGNORE_COSMETIC_TEXT end
  
  -- These Ignore options require tooltip scanning
  if not DTL:ScanBagSlot(item.Bag, item.Slot) then
    if -- Only return false if one of these options is enabled
      DB.Profile.IgnoreBindsWhenEquipped or
      DB.Profile.IgnoreSoulbound or
      DB.Profile.IgnoreEquipmentSets or
      DB.Profile.IgnoreTradeable
    then
      self.incompleteTooltips = true
      return false, "..."
    end
  else -- Tooltip can be scanned
    if self:IsIgnoredBindsWhenEquippedItem(item) then
      return false, L.REASON_IGNORE_BOE_TEXT
    elseif self:IsIgnoredSoulboundItem(item) then
      return false, L.REASON_IGNORE_SOULBOUND_TEXT
    elseif self:IsIgnoredEquipmentSetsItem(item) then
      return false, L.REASON_IGNORE_EQUIPMENT_SETS_TEXT
    elseif self:IsIgnoredTradeableItem(item) then
      return false, L.REASON_IGNORE_TRADEABLE_TEXT
    end
  end

  -- Sell by type
  if self:IsUnsuitableItem(item) then
    return true, L.REASON_SELL_UNSUITABLE_TEXT
  end

  local isBelowType, itemLevel = self:IsSellBelowAverageILVLItem(item)
  if (isBelowType == "BELOW") then
    return true, format(L.REASON_SELL_EQUIPMENT_BELOW_ILVL_TEXT, itemLevel)
  elseif (isBelowType == "ABOVE") then
    return false, format(L.REASON_IGNORE_EQUIPMENT_ABOVE_ILVL_TEXT, itemLevel)
  end

  -- 4
  if self:IsSellByQualityItem(item.Quality) then
    return true, L.REASON_SELL_BY_QUALITY_TEXT
  end

  -- Default
  return false, L.REASON_ITEM_NOT_FILTERED_TEXT
end

do -- Sell options
  function Dejunker:IsSellByQualityItem(quality)
    return
    ((quality == LE_ITEM_QUALITY_POOR) and DB.Profile.SellPoor) or
    ((quality == LE_ITEM_QUALITY_COMMON) and DB.Profile.SellCommon) or
    ((quality == LE_ITEM_QUALITY_UNCOMMON) and DB.Profile.SellUncommon) or
    ((quality == LE_ITEM_QUALITY_RARE) and DB.Profile.SellRare) or
    ((quality == LE_ITEM_QUALITY_EPIC) and DB.Profile.SellEpic)
  end

  function Dejunker:IsUnsuitableItem(item)
    if not DB.Profile.SellUnsuitable then return false end

    local suitable = true

    if (item.Class == Consts.ARMOR_CLASS) then
      local index = Consts.ARMOR_SUBCLASSES[item.SubClass]
      suitable = (Consts.SUITABLE_ARMOR[index] or (item.EquipSlot == "INVTYPE_CLOAK"))
    elseif (item.Class == Consts.WEAPON_CLASS) then
      local index = Consts.WEAPON_SUBCLASSES[item.SubClass]
      suitable = Consts.SUITABLE_WEAPONS[index]
    end

    return not suitable
  end

  do -- IsSellBelowAverageILVLItem
    local GetAverageItemLevel = GetAverageItemLevel

    -- Special check required for these generic armor types
    local SPECIAL_ARMOR_EQUIPSLOTS = {
      ["INVTYPE_FINGER"] = true,
      ["INVTYPE_NECK"] = true,
      ["INVTYPE_TRINKET"] = true,
      ["INVTYPE_HOLDABLE"] = true
    }

    -- Returns true if the item is an equippable item;
    -- excluding generic armor/weapon types, cosmetic items, and fishing poles.
    -- @return - boolean
    local function IsEquipmentItem(item)
      if (item.Class == Consts.ARMOR_CLASS) then
        if SPECIAL_ARMOR_EQUIPSLOTS[item.EquipSlot] then return true end
        local scValue = Consts.ARMOR_SUBCLASSES[item.SubClass]
        return (scValue ~= LE_ITEM_ARMOR_GENERIC) and (scValue ~= LE_ITEM_ARMOR_COSMETIC)
      elseif (item.Class == Consts.WEAPON_CLASS) then
        local scValue = Consts.WEAPON_SUBCLASSES[item.SubClass]
        return (scValue ~= LE_ITEM_WEAPON_GENERIC) and (scValue ~= LE_ITEM_WEAPON_FISHINGPOLE)
      else
        return false
      end
    end

    function Dejunker:IsSellBelowAverageILVLItem(item)
      if not DB.Profile.SellBelowAverageILVL.Enabled or
      not IsEquipmentItem(item) then return nil end

      local average = floor(GetAverageItemLevel())
      local diff = max(average - DB.Profile.SellBelowAverageILVL.Value, 0)

      if (item.ItemLevel <= diff) then -- Sell
        return "BELOW", diff
      else  -- Ignore, unless poor quality
        if (item.Quality >= LE_ITEM_QUALITY_COMMON) then
          return "ABOVE", diff
        end
      end
    end
  end
end

do -- Ignore options
  function Dejunker:IsIgnoredBattlePetItem(item)
    if not DB.Profile.IgnoreBattlePets then return false end

    return (item.Class == Consts.BATTLEPET_CLASS) or
          (item.SubClass == Consts.COMPANION_SUBCLASS)
  end

  function Dejunker:IsIgnoredConsumableItem(item)
    if not DB.Profile.IgnoreConsumables then return false end

    if (item.Class == Consts.CONSUMABLE_CLASS) then
      -- Ignore poor quality consumables to avoid confusion
      return (item.Quality ~= LE_ITEM_QUALITY_POOR)
    end

    return false
  end

  function Dejunker:IsIgnoredGemItem(item)
    if not DB.Profile.IgnoreGems then return false end
    return (item.Class == Consts.GEM_CLASS)
  end

  function Dejunker:IsIgnoredGlyphItem(item)
    if not DB.Profile.IgnoreGlyphs then return false end
    return (item.Class == Consts.GLYPH_CLASS)
  end

  function Dejunker:IsIgnoredItemEnhancementItem(item)
    if not DB.Profile.IgnoreItemEnhancements then return false end
    return (item.Class == Consts.ITEM_ENHANCEMENT_CLASS)
  end

  function Dejunker:IsIgnoredRecipeItem(item)
    if not DB.Profile.IgnoreRecipes then return false end
    return (item.Class == Consts.RECIPE_CLASS)
  end

  function Dejunker:IsIgnoredTradeGoodsItem(item)
    if not DB.Profile.IgnoreTradeGoods then return false end
    return (item.Class == Consts.TRADEGOODS_CLASS)
  end

  do -- IsIgnoredCosmeticItem
    -- Ignore these generic types since they provide no cosmetic appearance
    local IGNORE_ARMOR_EQUIPSLOTS = {
      ["INVTYPE_FINGER"] = true,
      ["INVTYPE_NECK"] = true,
      ["INVTYPE_TRINKET"] = true
    }

    function Dejunker:IsIgnoredCosmeticItem(item)
      if
        not DB.Profile.IgnoreCosmetic or
        not (item.Class == Consts.ARMOR_CLASS) or
        IGNORE_ARMOR_EQUIPSLOTS[item.EquipSlot]
      then
        return false
      end
      
      local subClass = Consts.ARMOR_SUBCLASSES[item.SubClass]
      return (subClass == LE_ITEM_ARMOR_COSMETIC) or (subClass == LE_ITEM_ARMOR_GENERIC)
    end
  end

  function Dejunker:IsIgnoredBindsWhenEquippedItem(item)
    return DB.Profile.IgnoreBindsWhenEquipped and
    (item.Quality ~= LE_ITEM_QUALITY_POOR) and
    DTL:IsBindsWhenEquipped()
  end

  function Dejunker:IsIgnoredSoulboundItem(item)
    return DB.Profile.IgnoreSoulbound and
    (item.Quality ~= LE_ITEM_QUALITY_POOR) and
    DTL:IsSoulbound()
  end

  do -- IsIgnoredEquipmentSetsItem
    local EQUIPMENT_SETS_CAPTURE = EQUIPMENT_SETS:gsub("%%s", "(.*)")

    function Dejunker:IsIgnoredEquipmentSetsItem(item)
      return DB.Profile.IgnoreEquipmentSets and
      (not not DTL:Match(false, EQUIPMENT_SETS_CAPTURE))
    end
  end

  function Dejunker:IsIgnoredTradeableItem(item)
    return DB.Profile.IgnoreTradeable and DTL:IsTradeable()
  end
end
