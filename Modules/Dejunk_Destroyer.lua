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

--[[
//*******************************************************************
//                         Destroyer Frame
//*******************************************************************
--]]

local DestroyerFrame = CreateFrame("Frame", AddonName.."DestroyerFrame")

function DestroyerFrame:OnEvent(event, ...)
  if (event == "UI_ERROR_MESSAGE") then
    local _, msg = ...

    if Destroyer:IsDestroying() then
			if (msg == ERR_INTERNAL_BAG_ERROR) then
				--UIErrorsFrame:Clear()
			end
		end
  end
end

DestroyerFrame:SetScript("OnEvent", DestroyerFrame.OnEvent)
DestroyerFrame:RegisterEvent("UI_ERROR_MESSAGE")

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

  DestroyerFrame:SetScript("OnUpdate", nil)

  currentState = DestroyerState.None

  for k in pairs(ItemsToDestroy) do ItemsToDestroy[k] = nil end
  for k in pairs(DestroyedItems) do DestroyedItems[k] = nil end
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

  DestroyerFrame:SetScript("OnUpdate", function(frame, elapsed)
    self:DestroyItems(frame, elapsed) end)
end

-- Cancels the destroying items process.
function Destroyer:StopDestroyingItems()
  DestroyerFrame:SetScript("OnUpdate", nil)

  self:StopDestroying()
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

  print("Would have destroyed: "..item.ItemLink)
  if true then return end

	UseContainerItem(item.Bag, item.Slot)
  DestroyedItems[#DestroyedItems+1] = item
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

  --if not Tools:ItemCanBeDestroyed(item.Quality) then return nil end -- Implement later
  if not self:IsDestroyableItem(item) then return nil end

  return item
end

-- Checks if an item is a junk item based on Dejunk's settings.
-- @param item - an item retrieved using Tools:GetItemFromBag
-- @return - true if the item is considered junk, and false otherwise
function Destroyer:IsDestroyableItem(item)
  -- Add more to this later as we begin to implement destroy options
  return ListManager:IsOnList(ListManager.Destroyables, item.ItemID)
end
