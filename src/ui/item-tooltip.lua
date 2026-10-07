local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Items = Addon:GetModule("Items")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
  if not StateManager:GetGlobalState().itemTooltips or Items:IsBagSlotEmpty(bag, slot) then return end

  local item = Items:GetItem(bag, slot)
  if not item then return end

  -- A filter type that cannot apply to the item has no reason.
  local isSellJunk, sellReason = JunkFilter:IsJunkItem(item, "SELL")
  local isDestroyJunk, destroyReason = JunkFilter:IsJunkItem(item, "DESTROY")
  if not (sellReason or destroyReason) then return end

  -- Add lines.
  self:AddLine(" ")
  self:AddLine(Colors.Blue(ADDON_NAME))

  -- Add selling lines.
  local sellColor = isSellJunk and Colors.Red or Colors.Green
  local sellHeading = sellColor(isSellJunk and L.SELLING or L.NOT_SELLING)
  self:AddLine(Colors.Grey("  %s:"):format(sellHeading))
  self:AddLine(Colors.Grey("  - ") .. Colors.White(sellReason or L.NO_FILTERS_MATCHED))

  -- Add destroying lines.
  local destroyColor = isDestroyJunk and Colors.Red or Colors.Green
  local destroyHeading = destroyColor(isDestroyJunk and L.DESTROYING or L.NOT_DESTROYING)
  self:AddLine(Colors.Grey("  %s:"):format(destroyHeading))
  self:AddLine(Colors.Grey("  - ") .. Colors.White(destroyReason or L.NO_FILTERS_MATCHED))

  self:Show()
end)
