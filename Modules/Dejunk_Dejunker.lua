--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

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

dejunkerFrame:SetScript("OnEvent", function(frame, event, ...)
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
end)

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
function Dejunker:GetDejunkableItemFromBag(bag, slot, itemID)
  local item = nil

  local itemID = (itemID or GetContainerItemID(bag, slot))
  local _, quantity, locked, quality, _, _,
    itemLink, _, noValue, itemID = GetContainerItemInfo(bag, slot)

  if (itemID and itemLink and quality and quantity and not locked and not noValue) then
    local price = select(11, GetItemInfo(itemLink)) -- Incorrect prices on scaled/upgraded items unless itemLink is used

    if (price and self:IsJunkItem(itemID, price, quality)) then
      item = {}
      item.Bag = bag
      item.Slot = slot
      item.ItemID = itemID
      item.Link = itemLink
      item.Quality = quality
      item.Quantity = quantity
      item.Price = price
    end
  end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param itemID - the id of the item
-- @param price - the price of the item
-- @param quality - the quality of the item
-- @return - true if the item is considered junk, and false otherwise
function Dejunker:IsJunkItem(itemID, price, quality)
  --[[ Priority
  1. Can item be sold?
  2. Is it excluded?
  3. Is it included?
  4. Custom checks
  5. Is it a Sell All item?
  6. Don't sell
  ]]

	-- 1
  -- NOTE: some items which cannot be sold do not return a true noValue field from GetContainerItemInfo
  if not Tools:ItemCanBeSold(price, quality) then
    return false end

  -- 2
  if ListManager:IsOnList(ListManager.Exclusions, itemID) then
    return false end

  -- 3
  if ListManager:IsOnList(ListManager.Inclusions, itemID) then
		return true end

  -- 4, custom checks can go here, if ever necessary

	-- 5
	if ((quality == LE_ITEM_QUALITY_POOR) and DejunkDB.SV.SellPoor) or
	   ((quality == LE_ITEM_QUALITY_COMMON) and DejunkDB.SV.SellCommon) or
	   ((quality == LE_ITEM_QUALITY_UNCOMMON) and DejunkDB.SV.SellUncommon) or
	   ((quality == LE_ITEM_QUALITY_RARE) and DejunkDB.SV.SellRare) or
	   ((quality == LE_ITEM_QUALITY_EPIC) and DejunkDB.SV.SellEpic) then
    return true -- such fat, much huge, wow
  end

  -- 6
  return false
end
