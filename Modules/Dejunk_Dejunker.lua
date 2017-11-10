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

--[[
//*******************************************************************
//                         Dejunker Frame
//*******************************************************************
--]]

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
  assert(currentState == DejunkerState.None)
  if ListManager:IsParsing() then return end

  currentState = DejunkerState.Dejunking
  Core:DisableGUI()

  allItemsCached = true

  self:SearchForJunkItems()

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

  Core:EnableGUI()
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
  local profit = Dejunker:CheckForNextSoldItem()

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

  local _, quantity, locked, _, _, _, itemLink = GetContainerItemInfo(item.Bag, item.Slot)

  if ((itemLink and quantity) and (itemLink == item.Link) and (quantity == item.Quantity)) then
    if locked then -- Item probably being sold, add it back to list and try again later
      SoldItems[#SoldItems+1] = item
    else -- Item is still in bags, so it may not have sold
      Core:Print(format(L.MAY_NOT_HAVE_SOLD_ITEM, item.Link))
    end

    return nil
  end

  -- Bag and slot is empty, so the item should have sold
  return (item.Price * item.Quantity)
end

--[[
//*******************************************************************
//                        Helper Functions
//*******************************************************************
--]]

-- Searches the player's bags for dejunkable items.
function Dejunker:SearchForJunkItems()
  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)

      if itemID then -- bag slot is not empty (seems to be guaranteed)
        if not GetItemInfo(itemID) then
          allItemsCached = false end

        local item = self:GetDejunkableItemFromBag(bag, slot, itemID)

        if item then -- item is cached
          ItemsToSell[#ItemsToSell+1] = item

          if ((#ItemsToSell == Consts.SAFE_MODE_MAX) and DejunkDB.SV.SafeMode) then
            Core:Print(L.SAFE_MODE_MESSAGE) return end
        end
      end
    end
  end
end

-- Returns the item in the specified bag slot if it is dejunkable.
-- @return - a dejunkable item, or nil
function Dejunker:GetDejunkableItemFromBag(bag, slot)
  local item = Tools:GetItemFromBag(bag, slot)
  if not item then return nil end

  if item.NoValue or not Tools:ItemCanBeSold(item.Price, item.Quality) then return nil end
  if not self:IsJunkItem(item) then return nil end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param itemID - the id of the item
-- @param price - the price of the item
-- @param quality - the quality of the item
-- @return - true if the item is considered junk, and false otherwise
function Dejunker:IsJunkItem(item)
  --[[ Priority
  1. Is it excluded?
  2. Is it included?
  3. Custom checks
  4. Is it a sell by quality item?
  ]]

  -- 1
  if ListManager:IsOnList(ListManager.Exclusions, item.ItemID) then
    return false end

  -- 2
  if ListManager:IsOnList(ListManager.Inclusions, item.ItemID) then
		return true end

  -- 3. Custom checks

  -- Sell options
  if self:IsUnsuitableItem(item) then return true end
  if self:IsEquipmentBelowILVLItem(item) then return true end

  -- Ignore options
  if self:IsIgnoredBattlePetItem(item) then return false end
  if self:IsIgnoredConsumableItem(item) then return false end
  if self:IsIgnoredGemItem(item) then return false end
  if self:IsIgnoredGlyphItem(item) then return false end
  if self:IsIgnoredItemEnhancementItem(item) then return false end
  if self:IsIgnoredRecipeItem(item) then return false end
  if self:IsIgnoredTradeGoodsItem(item) then return false end

	-- 4
  return self:IsSellByQualityItem(item.Quality)
end

--[[
//*******************************************************************
//                        Filter Functions
//*******************************************************************
--]]

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

  local class, subClass, equipSlot = item.Class, item.SubClass, item.EquipSlot
  local suitable = true

  if (class == Consts.ARMOR_CLASS) then
    local index = Consts.ARMOR_SUBCLASSES[subClass]
    suitable = (Consts.SUITABLE_ARMOR[index] or (equipSlot == "INVTYPE_CLOAK"))
  elseif (class == Consts.WEAPON_CLASS) then
    local index = Consts.WEAPON_SUBCLASSES[subClass]
    suitable = Consts.SUITABLE_WEAPONS[index]
  end

  return not suitable
end

function Dejunker:IsEquipmentBelowILVLItem(item)
  local class, subClass, equipSlot, itemLevel = item.Class, item.SubClass, item.EquipSlot, item.ItemLevel

  if not DejunkDB.SV.SellEquipmentBelowILVL.Enabled or
    (itemLevel >= DejunkDB.SV.SellEquipmentBelowILVL.Value) then
    return false
  end

  if (class == Consts.ARMOR_CLASS) then
    -- Special case for rings, necklaces, and trinkets since they are generic armor types.
    local invtypes = { ["INVTYPE_FINGER"] = true, ["INVTYPE_NECK"] = true, ["INVTYPE_TRINKET"] = true }
    if invtypes[equipSlot] then return true end

    local scValue = Consts.ARMOR_SUBCLASSES[subClass]
    return (scValue ~= LE_ITEM_ARMOR_GENERIC) and (scValue ~= LE_ITEM_ARMOR_COSMETIC)
  elseif (class == Consts.WEAPON_CLASS) then
    local scValue = Consts.WEAPON_SUBCLASSES[subClass]
    return (scValue ~= LE_ITEM_WEAPON_GENERIC) and (scValue ~= LE_ITEM_WEAPON_FISHINGPOLE)
  else
    return false
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
