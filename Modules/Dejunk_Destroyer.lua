-- Dejunk_Destroyer: handles the process of destroying items in the player's bags.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local remove = table.remove

-- Dejunk
local Destroyer = DJ.Destroyer

local Core = DJ.Core
local Consts = DJ.Consts
local DejunkDB = DJ.DejunkDB
local ListManager = DJ.ListManager
local Tools = DJ.Tools

-- Variables
local DestroyerState =
{
  None = 0,
  Destroying = 1
}

local currentState = DestroyerState.None

local ItemsToDestroy = {}
local DestroyedItems = {}
local numDestroyedItems = 0

--[[
//*******************************************************************
//                         Destroyer Frame
//*******************************************************************
--]]

local destroyerFrame = CreateFrame("Frame", AddonName.."DestroyerFrame")

function destroyerFrame:OnEvent(event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if Destroyer:IsDestroying() then
			if (msg == ERR_INTERNAL_BAG_ERROR) then
				--UIErrorsFrame:Clear()
			end
		end
  end
end

destroyerFrame:SetScript("OnEvent", destroyerFrame.OnEvent)
destroyerFrame:RegisterEvent("UI_ERROR_MESSAGE")

--[[
//*******************************************************************
//                        Destroying Functions
//*******************************************************************
--]]

-- Starts the Destroying process.
function Destroyer:StartDestroying()
  local canDestroy, msg = Core:CanDestroy()
  if not canDestroy then
    Core:Print(msg)
    return
  end

  currentState = DestroyerState.Destroying
  allItemsCached = true

  self:SearchForDestroyableItems()

  if not allItemsCached then
    if (#ItemsToDestroy > 0) then
      Core:Print("Only destroying cached items. (L)")
    else
      Core:Print("No cached destroyable items. (L)")
      self:StopDestroying()
      return
    end
  end

  self:StartDestroyingItems()
end

-- Cancels the Destroying process.
function Destroyer:StopDestroying()
  assert(currentState ~= DestroyerState.None)

  destroyerFrame:SetScript("OnUpdate", nil)

  currentState = DestroyerState.None

  for k in pairs(ItemsToDestroy) do ItemsToDestroy[k] = nil end
  for k in pairs(DestroyedItems) do DestroyedItems[k] = nil end
  numDestroyedItems = 0
end

-- Checks whether or not the Destroyer is active.
-- @return - boolean
function Destroyer:IsDestroying()
  return (currentState ~= DestroyerState.None)
end

--[[
//*******************************************************************
//                        Destroy Item Functions
//*******************************************************************
--]]

local DESTROY_DELAY = 0.25
local destroyInterval = 0

-- Starts the destroying items process.
function Destroyer:StartDestroyingItems()
  assert(currentState == DestroyerState.Destroying)

  if (#ItemsToDestroy <= 0) then
		Core:Print("No items to destroy. (L)")
		self:StopDestroying()
		return
	end

  destroyInterval = 0

  destroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:DestroyItems(frame, elapsed) end)
end

-- Cancels the destroying items process.
function Destroyer:StopDestroyingItems()
  destroyerFrame:SetScript("OnUpdate", nil)

  self:StartLosing()
end

-- Set as the OnUpdate function during the destroying items process.
function Destroyer:DestroyItems(frame, elapsed)
	destroyInterval = (destroyInterval + elapsed)

	if (destroyInterval >= DESTROY_DELAY) then
		destroyInterval = 0

		self:DestroyNextItem()

		if (#ItemsToDestroy <= 0) then
      self:StopDestroyingItems() end
	end
end

-- Destroys the next item in the ItemsToDestroy table.
function Destroyer:DestroyNextItem()
  local item = remove(ItemsToDestroy)
	if not item then return end

  --print("Would have destroyed: "..item.ItemLink)
  --if true then return end

  print("Destroying: "..item.ItemLink)

	PickupContainerItem(item.Bag, item.Slot)
  DeleteCursorItem()
  ClearCursor()

  DestroyedItems[#DestroyedItems+1] = item
end

--[[
//*******************************************************************
//                         Loss Functions
//*******************************************************************
--]]

local totalLoss = 0

-- Starts the loss calculation process.
function Destroyer:StartLosing()
  assert(currentState == DestroyerState.Destroying)

  if (#DestroyedItems <= 0) then
    self:StopDestroying()
    return
  end

  totalLoss = 0
  destroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:CalculateLoss()
  end)
end

-- Cancels the losing process.
function Destroyer:StopLosing()
  assert(currentState == DestroyerState.Destroying)

  destroyerFrame:SetScript("OnUpdate", nil)

  if (numDestroyedItems == 1) then
    Core:Print(format("Destroyed 1 item worth %s. (L)",
      GetCoinTextureString(totalLoss)))
  else
    Core:Print(format("Destroyed %s items worth %s in total. (L)",
      numDestroyedItems, GetCoinTextureString(totalLoss)))
  end

  self:StopDestroying()
end

-- Set as the OnUpdate function during the losing process.
function Destroyer:CalculateLoss()
  local loss = Destroyer:CheckForNextDestroyedItem()

  if loss then
    totalLoss = (totalLoss + loss)
  end

  if (#DestroyedItems <= 0) then
    self:StopLosing() end
end

-- Checks if the next entry in DestroyedItems has been destroyed and returns the loss.
-- @return - loss if the item was destroyed, or nil if not
function Destroyer:CheckForNextDestroyedItem()
  local item = remove(DestroyedItems, 1)
  if not item then return nil end

  local _, quantity, locked, _, _, _, itemLink = GetContainerItemInfo(item.Bag, item.Slot)

  if ((itemLink and quantity) and (itemLink == item.Link) and (quantity == item.Quantity)) then
    if locked then -- Item probably being destroyed, add it back to list and try again later
      DestroyedItems[#DestroyedItems+1] = item
    else -- Item is still in bags, so it may not have been destroyed
      Core:Print(format("May not have destroyed %s. (L)", item.Link))
    end

    return nil
  end

  -- Bag and slot is empty, so the item should have been destroyed
  numDestroyedItems = (numDestroyedItems + item.Quantity)
  return (item.Price * item.Quantity)
end

--[[
//*******************************************************************
//                        Helper Functions
//*******************************************************************
--]]

-- Searches the player's bags for destroyable items.
function Destroyer:SearchForDestroyableItems()
  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)

      if itemID then -- bag slot is not empty (seems to be guaranteed)
        if not GetItemInfo(itemID) then
          allItemsCached = false end

        local item = self:GetDestroyableItemFromBag(bag, slot, itemID)

        if item then -- item is cached
          ItemsToDestroy[#ItemsToDestroy+1] = item
        end
      end
    end
  end
end

-- Returns the item in the specified bag slot if it is destroyable.
-- @return - a destroyable item, or nil
function Destroyer:GetDestroyableItemFromBag(bag, slot)
  local item = Tools:GetItemFromBag(bag, slot)
  if not item then return nil end

  if not Tools:ItemCanBeDestroyed(item.Quality) then return nil end
  if not self:IsDestroyableItem(item) then return nil end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param item - an item retrieved using Tools:GetItemFromBag
-- @return - true if the item is considered junk, and false otherwise
function Destroyer:IsDestroyableItem(item)
  --[[ Priority
  1. Are we ignoring Exclusions?
  2. Are we destroying Poor items?
    2.1 Treshold?
  3. Are we destroying Inclusions?
    3.1 Treshold?
  4. Is it on the Destroyables list?
    4.1 Treshold?
  ]]

  -- 1
  if DejunkDB.SV.DestroyIgnoreExclusions and
    ListManager:IsOnList(ListManager.Exclusions, item.ItemID) then
    print(format("Ignoring %s since it is on Exclusions.", item.ItemLink))
    return false
  end

  -- 2
  if DejunkDB.SV.DestroyPoor and (item.Quality == LE_ITEM_QUALITY_POOR) then
    print(format("Destroying %s since it is a Poor item.", item.ItemLink))
    return self:ItemPriceBelowThreshold(item)
  end

  -- 3
  if DejunkDB.SV.DestroyInclusions and
    ListManager:IsOnList(ListManager.Inclusions, item.ItemID) then
    print(format("Destroying %s since it is on Inclusions.", item.ItemLink))
    return self:ItemPriceBelowThreshold(item)
  end

  -- 4
  return ListManager:IsOnList(ListManager.Destroyables, item.ItemID) and
    self:ItemPriceBelowThreshold(item)
end

-- Returns true if the item's price is less than the set price treshold.
function Destroyer:ItemPriceBelowThreshold(item)
  if DejunkDB.SV.DestroyUsePriceThreshold and Tools:ItemCanBeSold(item.Price, item.Quality) then
    local threshold = DejunkDB.SV.DestroyPriceThreshold
    local thresholdCopperPrice = (threshold.Gold * 10000) +
      (threshold.Silver * 100) + threshold.Copper

    if ((item.Price * item.Quantity) >= thresholdCopperPrice) then
      print(format("Ignoring %s since it is worth equal to or more than the threshold.", item.ItemLink))
      print("Item price: "..GetCoinTextureString((item.Price * item.Quantity)))
      print("Calculated threshold price: "..GetCoinTextureString(thresholdCopperPrice))
      return false
    end
  end

  return true
end
