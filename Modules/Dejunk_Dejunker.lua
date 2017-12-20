-- Dejunk_Dejunker: handles the process of selling junk items to merchants.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local remove = table.remove

-- Dejunk
local Dejunker = DJ.Dejunker

local Core = DJ.Core
local Consts = DJ.Consts
local DejunkDB = DJ.DejunkDB
local ListManager = DJ.ListManager
local Tools = DJ.Tools

-- Variables
local DejunkerState =
{
  None = 0,
  Dejunking = 1,
  Selling = 2,
  Profiting = 3
}

local currentState = DejunkerState.None

local ItemsToSell = {}
local SoldItems = {}

-- ============================================================================
--                             Dejunker Frame
-- ============================================================================

local dejunkerFrame = CreateFrame("Frame", AddonName.."DejunkerFrame")

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

--[[
//*******************************************************************
//                        Dejunking Functions
//*******************************************************************
--]]

-- Starts the Dejunking process.
function Dejunker:StartDejunking()
  local canDejunk, msg = Core:CanDejunk()
  if not canDejunk then
    Core:Print(msg)
    return
  end

  currentState = DejunkerState.Dejunking

  local items, allItemsCached

  if DejunkDB.SV.SafeMode then
    items, allItemsCached = Tools:GetBagItemsByFilter(self.Filter, Consts.SAFE_MODE_MAX)
    if (#items == Consts.SAFE_MODE_MAX) then
      Core:Print(format(L.SAFE_MODE_MESSAGE, Consts.SAFE_MODE_MAX)) end
  else
    items, allItemsCached = Tools:GetBagItemsByFilter(self.Filter)
  end

  ItemsToSell = items

  if not allItemsCached then
    if (#ItemsToSell > 0) then
      Core:Print(L.ONLY_SELLING_CACHED)
    else
      Core:Print(L.NO_CACHED_JUNK_ITEMS)
      self:StopDejunking()
      return
    end
  end

  self:StartSelling()
end

-- Cancels the Dejunking process.
function Dejunker:StopDejunking()
  assert(currentState ~= DejunkerState.None)

  dejunkerFrame:SetScript("OnUpdate", nil)

  currentState = DejunkerState.None

  for k in pairs(ItemsToSell) do ItemsToSell[k] = nil end
  for k in pairs(SoldItems) do SoldItems[k] = nil end
end

-- Checks whether or not the Dejunker is active.
-- @return - boolean
function Dejunker:IsDejunking()
  return (currentState ~= DejunkerState.None)
end

--[[
//*******************************************************************
//                        Selling Functions
//*******************************************************************
--]]

local SELL_DELAY = 0.25
local sellInterval = 0

-- Starts the selling process.
function Dejunker:StartSelling()
  assert(currentState == DejunkerState.Dejunking)

  if (#ItemsToSell <= 0) then
		Core:Print(L.NO_JUNK_ITEMS)
		self:StopDejunking()
		return
	end

  currentState = DejunkerState.Selling
  sellInterval = 0

  dejunkerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:SellItems(frame, elapsed) end)
end

-- Cancels the selling process and starts the profiting process.
function Dejunker:StopSelling()
  assert(currentState == DejunkerState.Selling)

  dejunkerFrame:SetScript("OnUpdate", nil)

  self:StartProfiting()
end

-- Checks whether or not the Dejunker is actively selling items.
-- @return - boolean
function Dejunker:IsSelling()
  return (currentState == DejunkerState.Selling)
end

-- Set as the OnUpdate function during the selling process.
function Dejunker:SellItems(frame, elapsed)
	sellInterval = (sellInterval + elapsed)

	if (sellInterval >= SELL_DELAY) then
		sellInterval = 0

		self:SellNextItem()

		if (#ItemsToSell <= 0) then
      self:StopSelling() end
	end
end

-- Sells the next item in the ItemsToSell table.
function Dejunker:SellNextItem()
  local item = remove(ItemsToSell)
  if not item then return end

  -- Verify that the item in the bag slot has not been changed before selling
  local bagItem = Tools:GetItemFromBag(item.Bag, item.Slot)
  if not bagItem or bagItem.Locked or (not (bagItem.ItemID == item.ItemID)) then return end

  UseContainerItem(item.Bag, item.Slot)
  SoldItems[#SoldItems+1] = item
end

--[[
//*******************************************************************
//                       Profiting Functions
//*******************************************************************
--]]

local totalProfit = 0

-- Starts the profiting process.
function Dejunker:StartProfiting()
  assert(currentState == DejunkerState.Selling)

  if (#SoldItems <= 0) then
    self:StopDejunking()
    return
  end

  currentState = DejunkerState.Profiting
  totalProfit = 0
  dejunkerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:CalculateProfits()
  end)
end

-- Cancels the profiting process.
function Dejunker:StopProfiting()
  assert(currentState == DejunkerState.Profiting)

  dejunkerFrame:SetScript("OnUpdate", nil)

  if (totalProfit > 0) then
    Core:Print(format(L.SOLD_YOUR_JUNK, GetCoinTextureString(totalProfit)))
  end

  self:StopDejunking()
end

-- Set as the OnUpdate function during the profiting process.
function Dejunker:CalculateProfits()
  local profit = self:CheckForNextSoldItem()

  if profit then
    totalProfit = (totalProfit + profit) end

  if (#SoldItems <= 0) then
    self:StopProfiting() end
end

-- Checks if the next entry in SoldItems has sold and returns the profit.
-- @return - profit if the item was sold, or nil if not
function Dejunker:CheckForNextSoldItem()
  local item = remove(SoldItems, 1)
  if not item then return nil end

  local bagItem = Tools:GetItemFromBag(item.Bag, item.Slot)
  if bagItem and (bagItem.ItemID == item.ItemID) and (bagItem.Quantity == item.Quantity) then
    if bagItem.Locked then -- Item probably being sold, add it back to list and try again later
      SoldItems[#SoldItems+1] = item
    else -- Item is still in bags, so it may not have sold
      Core:Print(format(L.MAY_NOT_HAVE_SOLD_ITEM, item.ItemLink))
    end

    return nil
  end

  -- Bag and slot is empty, so the item should have sold
  if (item.Quantity == 1) then
    Core:PrintVerbose(format(L.SOLD_ITEM_VERBOSE, item.ItemLink))
  else
    Core:PrintVerbose(format(L.SOLD_ITEMS_VERBOSE, item.ItemLink, item.Quantity))
  end

  return (item.Price * item.Quantity)
end

--[[
//*******************************************************************
//                        Filter Functions
//*******************************************************************
--]]

-- Filter function
-- Returns the item in the specified bag slot if it is dejunkable.
-- @return - a dejunkable item, or nil
Dejunker.Filter = function(bag, slot)
  local item = Tools:GetItemFromBag(bag, slot)
  if not item or item.Locked then return nil end

  if item.NoValue or not Tools:ItemCanBeSold(item) then return nil end
  if not Dejunker:IsJunkItem(item) then return nil end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param item - an item retrieved using Tools:GetItemFromBag
-- @return boolean - true if the item is considered junk
-- @return string - the reason the item is considered junk or not
function Dejunker:IsJunkItem(item)
  --[[ Priority
  1. Is it excluded?
  2. Is it included?
  3. Custom checks
  4. Is it a sell by quality item?
  ]]

  -- 1
  if ListManager:IsOnList(ListManager.Exclusions, item.ItemID) then
    return false, format(L.REASON_ITEM_ON_LIST_TEXT, L.EXCLUSIONS_TEXT) end

  -- 2
  if ListManager:IsOnList(ListManager.Inclusions, item.ItemID) then
		return true, format(L.REASON_ITEM_ON_LIST_TEXT, L.INCLUSIONS_TEXT) end

  -- 3. Custom checks

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
    return true, L.REASON_SELL_UNSUITABLE_TEXT end

  local isBelowType = self:IsSellEquipmentBelowILVLItem(item)
  if (isBelowType == "BELOW") then
    return true, format(L.REASON_SELL_EQUIPMENT_BELOW_ILVL_TEXT,
    DejunkDB.SV.SellEquipmentBelowILVL.Value)
  elseif (isBelowType == "ABOVE") then
    return false, format(L.REASON_IGNORE_EQUIPMENT_ABOVE_ILVL_TEXT,
    DejunkDB.SV.SellEquipmentBelowILVL.Value)
  end

	-- Sell by quality
  if self:IsSellByQualityItem(item.Quality) then
    return true, L.REASON_SELL_BY_QUALITY_TEXT end

  -- Default
  return false, L.REASON_ITEM_NOT_FILTERED_TEXT
end

-- [[ SELL OPTIONS ]] --

function Dejunker:IsSellByQualityItem(quality)
  return ((quality == LE_ITEM_QUALITY_POOR) and DejunkDB.SV.SellPoor) or
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

do -- IsSellEquipmentBelowILVLItem
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

  function Dejunker:IsSellEquipmentBelowILVLItem(item)
    if not DejunkDB.SV.SellEquipmentBelowILVL.Enabled or
    not IsEquipmentItem(item) then return nil end

    if (item.ItemLevel >= DejunkDB.SV.SellEquipmentBelowILVL.Value) then
      return (item.Quality >= LE_ITEM_QUALITY_COMMON) and "ABOVE" or nil
    else return "BELOW" end
  end
end

-- [[ IGNORE OPTIONS ]] --

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
  if not DejunkDB.SV.IgnoreSoulbound then return false end
  return Tools:BagItemTooltipHasText(item.Bag, item.Slot, ITEM_SOULBOUND)
end

do -- IsIgnoredEquipmentSetsItem
  local TRIMMED_EQUIPMENT_SETS = nil

  function Dejunker:IsIgnoredEquipmentSetsItem(item)
    if not DejunkDB.SV.IgnoreEquipmentSets then return false end
    if not TRIMMED_EQUIPMENT_SETS then
      TRIMMED_EQUIPMENT_SETS =
        strtrim(Tools:RemoveColorFromString(EQUIPMENT_SETS:gsub("%%s", "")), " ")
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
