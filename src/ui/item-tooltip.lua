local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local BagItemsCache = Addon:GetModule("BagItemsCache")
local Colors = Addon:GetModule("Colors")
local Items = Addon:GetModule("Items")
local JunkItemsCache = Addon:GetModule("JunkItemsCache")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")

--- @class ItemTooltip
local ItemTooltip = Addon:GetModule("ItemTooltip")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the heading and the reason line, neither indented.
--- @param isJunk boolean
--- @param reason string?
--- @param junkText string
--- @param notJunkText string
--- @return string heading
--- @return string reason
local function getLines(isJunk, reason, junkText, notJunkText)
  local color = isJunk and Colors.Red or Colors.Green
  return color(isJunk and junkText or notJunkText) .. Colors.Grey(":"),
      Colors.Grey("- ") .. Colors.White(reason or L.NO_FILTERS_MATCHED)
end

-- ============================================================================
-- ItemTooltip
-- ============================================================================

--- Returns the `Selling` or `Not Selling` heading and the reason line. A `nil` reason reads `No filters matched`.
--- @param isJunk boolean
--- @param reason string?
--- @return string heading
--- @return string reason
function ItemTooltip:GetSellLines(isJunk, reason)
  return getLines(isJunk, reason, L.SELLING, L.NOT_SELLING)
end

--- Returns the `Destroying` or `Not Destroying` heading and the reason line. A `nil` reason reads `No filters matched`.
--- @param isJunk boolean
--- @param reason string?
--- @return string heading
--- @return string reason
function ItemTooltip:GetDestroyLines(isJunk, reason)
  return getLines(isJunk, reason, L.DESTROYING, L.NOT_DESTROYING)
end

-- ============================================================================
-- Bag Item Tooltip
-- ============================================================================

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
  if not StateManager:GetGlobalState().itemTooltips or Items:IsBagSlotEmpty(bag, slot) then return end

  local item = BagItemsCache:GetItem(bag, slot)
  if not item then return end

  local isSellJunk, sellReason = JunkItemsCache:IsSellableJunkItem(item)
  local isDestroyJunk, destroyReason = JunkItemsCache:IsDestroyableJunkItem(item)

  -- Add lines.
  self:AddLine(" ")
  self:AddLine(Colors.Blue(ADDON_NAME))

  -- Add selling lines.
  local sellHeading, sellReasonLine = ItemTooltip:GetSellLines(isSellJunk, sellReason)
  self:AddLine("  " .. sellHeading)
  self:AddLine("  " .. sellReasonLine)

  -- Add destroying lines.
  local destroyHeading, destroyReasonLine = ItemTooltip:GetDestroyLines(isDestroyJunk, destroyReason)
  self:AddLine("  " .. destroyHeading)
  self:AddLine("  " .. destroyReasonLine)

  self:Show()
end)
