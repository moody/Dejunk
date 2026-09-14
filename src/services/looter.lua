local Addon = select(2, ...) ---@type Addon
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")

--- @class Looter
local Looter = Addon:GetModule("Looter")

-- ============================================================================
-- Local Functions
-- ============================================================================

local canLootItems
do
  local frames = {
    "BankFrame",
    "MerchantFrame",
    "TradeFrame",
    "GameMenuFrame",

    -- Classic
    "AuctionFrame",

    -- Retail
    "AuctionHouseFrame",
    "AzeriteRespecFrame",
    "GuildBankFrame",
    "ScrappingMachineFrame",
    "VoidStorageFrame",
    "SettingsPanel",
    "EditModeManagerFrame"
  }

  --- Returns `false` while a frame that conflicts with looting is shown.
  --- @return boolean
  canLootItems = function()
    for _, key in pairs(frames) do
      local frame = _G[key]
      if frame and frame.IsShown and frame:IsShown() then
        return false
      end
    end
    return true
  end
end

-- ============================================================================
-- Looter
-- ============================================================================

--- Attempts to open `item`. Does nothing if it is no longer in the bags or
--- is locked.
--- @param item BagItem
function Looter:HandleItem(item)
  if Addon:IsBusy() then return end
  if not Items:IsItemStillInBags(item) then return end
  if Items:IsItemLocked(item) then return end

  if not canLootItems() then
    return Addon:Print(L.CANNOT_OPEN_LOOTABLE_ITEMS)
  end

  C_Container.UseContainerItem(item.bag, item.slot)
end
