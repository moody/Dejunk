-- Dejunk_Dejunker: handles the process of selling junk items to merchants.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL
local DCL = Addon.Libs.DCL

-- Upvalues
local assert, remove = assert, table.remove

-- Modules
local Dejunker = Addon.Dejunker
local Confirmer = Addon.Confirmer

local Core = Addon.Core
local Consts = Addon.Consts
local DejunkDB = Addon.DejunkDB
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

-- ============================================================================
-- Dejunker Frame
-- ============================================================================

local dejunkerFrame = CreateFrame("Frame", AddonName.."DejunkerFrame")

do -- OnEvent
  local ERR_INTERNAL_BAG_ERROR = ERR_INTERNAL_BAG_ERROR
  local ERR_VENDOR_DOESNT_BUY = ERR_VENDOR_DOESNT_BUY

  function dejunkerFrame:OnEvent(event, ...)
    if (event == "UI_ERROR_MESSAGE") then
      local _, msg = ...

      if Dejunker:IsDejunking() then
        if (msg == ERR_INTERNAL_BAG_ERROR) then
          UIErrorsFrame:Clear()
        elseif (msg == ERR_VENDOR_DOESNT_BUY) then
          UIErrorsFrame:Clear()
          Core:Print(L.VENDOR_DOESNT_BUY)
          Dejunker:StopDejunking()
        end
      end
    end
  end

  dejunkerFrame:SetScript("OnEvent", dejunkerFrame.OnEvent)
  dejunkerFrame:RegisterEvent("UI_ERROR_MESSAGE")
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

    Confirmer:OnDejunkerStart()
    currentState = states.Dejunking

    -- Get junk items
    local maxItems = DejunkDB.SV.SafeMode and Consts.SAFE_MODE_MAX
    DBL:GetItemsByFilter(Dejunker.Filter, itemsToSell, maxItems)
    local upToDate = DBL:IsUpToDate()

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
    if DejunkDB.SV.SafeMode and (#itemsToSell == Consts.SAFE_MODE_MAX) then
      Core:Print(format(L.SAFE_MODE_MESSAGE, Consts.SAFE_MODE_MAX))
    end

    self:StartSelling()
  end

  -- Cancels the Dejunking process.
  function Dejunker:StopDejunking()
    assert(currentState ~= states.None)

    dejunkerFrame:SetScript("OnUpdate", nil)

    Confirmer:OnDejunkerEnd()
    currentState = states.None
  end

  -- Checks whether or not the Dejunker is active.
  -- @return - boolean
  function Dejunker:IsDejunking()
    return (currentState ~= states.None) or Confirmer:IsConfirmingDejunkedItems()
  end
end

-- ============================================================================
-- Selling Functions
-- ============================================================================

do
  local StaticPopup1, StaticPopup1Text, StaticPopup1Button1 =
        StaticPopup1, StaticPopup1Text, StaticPopup1Button1

  -- NOTE: If a delay is not used, it can sometimes cause a disconnect
  -- I may turn this into an gui option at some point
  local SELL_DELAY = 0.25
  local sellInterval = 0

  -- Selling update function
  local function sellItems_OnUpdate(self, elapsed)
    sellInterval = (sellInterval + elapsed)
    if (sellInterval >= SELL_DELAY) then
      sellInterval = 0

      -- Get next item
      local item = remove(itemsToSell)
      -- Verify that the item in the bag slot has not been changed before selling
      if not item or not DBL:StillInBags(item) or item:IsLocked() then return end
      -- Sell item
      UseContainerItem(item.Bag, item.Slot)
      -- Accept tradeable item dialog if shown
      local popup = StaticPopup1:IsVisible() and (StaticPopup1Text.text_arg1 == item.ItemLink)
      if popup then StaticPopup1Button1:Click() end
      -- Notify confirmer
      Confirmer:OnItemDejunked(item)

      -- If no more items, stop selling
      if (#itemsToSell <= 0) then
        Dejunker:StopSelling()
      end
    end
  end

  -- Starts the selling process.
  function Dejunker:StartSelling()
    assert(currentState == states.Dejunking)
    assert(#itemsToSell > 0)

    currentState = states.Selling
    sellInterval = 0
    
    dejunkerFrame:SetScript("OnUpdate", sellItems_OnUpdate)
  end

  -- Cancels the selling process and stops dejunking.
  function Dejunker:StopSelling()
    assert(currentState == states.Selling)
    dejunkerFrame:SetScript("OnUpdate", nil)
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

do
  -- Returns true if the specified item is dejunkable.
  -- @param item - the item to run through the filter
  Dejunker.Filter = function(item)
    if item:IsLocked() or item.NoValue or not Tools:ItemCanBeSold(item) then return false end
    local isJunkItem = Dejunker:IsJunkItem(item)
    return isJunkItem
  end

  -- Checks if an item is a junk item based on Dejunk's settings.
  -- @param item - a DethsBagLib item
  -- @return boolean - true if the item is considered junk
  -- @return string - the reason the item is or is not considered junk
  function Dejunker:IsJunkItem(item)
    --[[ Priority
    1. Is it excluded?
    2. Is it included?
    3. Custom checks
    4. Is it a sell by quality item?
    ]]

    -- 1
    if ListManager:IsOnList(ListManager.Exclusions, item.ItemID) then
      return false, format(L.REASON_ITEM_ON_LIST_TEXT, L.EXCLUSIONS_TEXT)
    end

    -- 2
    if ListManager:IsOnList(ListManager.Inclusions, item.ItemID) then
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
    if self:IsIgnoredBindsWhenEquippedItem(item) then
      return false, L.REASON_IGNORE_BOE_TEXT end
    if self:IsIgnoredSoulboundItem(item) then
      return false, L.REASON_IGNORE_SOULBOUND_TEXT end
    if self:IsIgnoredEquipmentSetsItem(item) then
      return false, L.REASON_IGNORE_EQUIPMENT_SETS_TEXT end
    if self:IsIgnoredTradeableItem(item) then
      return false, L.REASON_IGNORE_TRADEABLE_TEXT end

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
      ((quality == LE_ITEM_QUALITY_POOR) and DejunkDB.SV.SellPoor) or
      ((quality == LE_ITEM_QUALITY_COMMON) and DejunkDB.SV.SellCommon) or
      ((quality == LE_ITEM_QUALITY_UNCOMMON) and DejunkDB.SV.SellUncommon) or
      ((quality == LE_ITEM_QUALITY_RARE) and DejunkDB.SV.SellRare) or
      ((quality == LE_ITEM_QUALITY_EPIC) and DejunkDB.SV.SellEpic)
    end

    function Dejunker:IsUnsuitableItem(item)
      if not DejunkDB.SV.SellUnsuitable then return false end

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
        if not DejunkDB.SV.SellBelowAverageILVL.Enabled or
        not IsEquipmentItem(item) then return nil end

        local average = floor(GetAverageItemLevel())
        local diff = max(average - DejunkDB.SV.SellBelowAverageILVL.Value, 0)

        if (item.ItemLevel <= diff) then -- Sell
          if (item.Quality >= LE_ITEM_QUALITY_COMMON) then
            return "BELOW", diff
          end
        else -- Ignore
          return "ABOVE", diff
        end
      end
    end
  end

  do -- Ignore options
    function Dejunker:IsIgnoredBattlePetItem(item)
      if not DejunkDB.SV.IgnoreBattlePets then return false end

      return (item.Class == Consts.BATTLEPET_CLASS) or
            (item.SubClass == Consts.COMPANION_SUBCLASS)
    end

    function Dejunker:IsIgnoredConsumableItem(item)
      if not DejunkDB.SV.IgnoreConsumables then return false end

      if (item.Class == Consts.CONSUMABLE_CLASS) then
        -- Ignore poor quality consumables to avoid confusion
        return (item.Quality ~= LE_ITEM_QUALITY_POOR)
      end

      return false
    end

    function Dejunker:IsIgnoredGemItem(item)
      if not DejunkDB.SV.IgnoreGems then return false end
      return (item.Class == Consts.GEM_CLASS)
    end

    function Dejunker:IsIgnoredGlyphItem(item)
      if not DejunkDB.SV.IgnoreGlyphs then return false end
      return (item.Class == Consts.GLYPH_CLASS)
    end

    function Dejunker:IsIgnoredItemEnhancementItem(item)
      if not DejunkDB.SV.IgnoreItemEnhancements then return false end
      return (item.Class == Consts.ITEM_ENHANCEMENT_CLASS)
    end

    function Dejunker:IsIgnoredRecipeItem(item)
      if not DejunkDB.SV.IgnoreRecipes then return false end
      return (item.Class == Consts.RECIPE_CLASS)
    end

    function Dejunker:IsIgnoredTradeGoodsItem(item)
      if not DejunkDB.SV.IgnoreTradeGoods then return false end
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
        if not DejunkDB.SV.IgnoreCosmetic or
        not (item.Class == Consts.ARMOR_CLASS) or
        IGNORE_ARMOR_EQUIPSLOTS[item.EquipSlot] then
          return false end

        local subClass = Consts.ARMOR_SUBCLASSES[item.SubClass]
        return (subClass == LE_ITEM_ARMOR_COSMETIC) or (subClass == LE_ITEM_ARMOR_GENERIC)
      end
    end

    function Dejunker:IsIgnoredBindsWhenEquippedItem(item)
      if not DejunkDB.SV.IgnoreBindsWhenEquipped then return false end
      -- Make sure the item is actually an armor or weapon item instead of a tradeskill recipe
      if not (item.Class == Consts.ARMOR_CLASS or item.Class == Consts.WEAPON_CLASS) then return false end
      return Tools:BagItemTooltipHasText(item.Bag, item.Slot, ITEM_BIND_ON_EQUIP)
    end

    function Dejunker:IsIgnoredSoulboundItem(item)
      if not DejunkDB.SV.IgnoreSoulbound or (item.Quality == LE_ITEM_QUALITY_POOR) then return false end
      return Tools:BagItemTooltipHasText(item.Bag, item.Slot, ITEM_SOULBOUND)
    end

    do -- IsIgnoredEquipmentSetsItem
      local TRIMMED_EQUIPMENT_SETS = nil

      function Dejunker:IsIgnoredEquipmentSetsItem(item)
        if not DejunkDB.SV.IgnoreEquipmentSets then return false end
        if not TRIMMED_EQUIPMENT_SETS then
          TRIMMED_EQUIPMENT_SETS =
            strtrim(DCL:RemoveColor(EQUIPMENT_SETS:gsub("%%s", "")), " ")
        end

        return Tools:BagItemTooltipHasText(item.Bag, item.Slot, TRIMMED_EQUIPMENT_SETS)
      end
    end

    do -- IsIgnoredTradeableItem
      local bttr1, bttr2 = BIND_TRADE_TIME_REMAINING:match("(.+)%%s(.+)")

      function Dejunker:IsIgnoredTradeableItem(item)
        if not DejunkDB.SV.IgnoreTradeable then return false end
        return Tools:BagItemTooltipHasLine(item.Bag, item.Slot, bttr1, bttr2)
      end
    end
  end
end
