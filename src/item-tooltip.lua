local AddonName, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DBL = Addon.Libs.DBL
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local L = Addon.Libs.L
local Tools = Addon.Tools

local item = {}

_G.hooksecurefunc(_G.GameTooltip, "SetBagItem", function(self, bag, slot)
  if not DB.Global.ItemTooltip or DBL:IsEmpty(bag, slot) then return end
  if not DBL:GetItem(bag, slot, item) then return end
  if Tools:ItemCanBeRefunded(item) then return end

  local sellLeftText, sellRightText
  local destroyLeftText, destroyRightText

  -- Sell text
  if Tools:ItemCanBeSold(item) then
    local isJunkItem, reasonText = Filters:Run(Dejunker, item)
    sellLeftText =
      isJunkItem and
      DCL:ColorString(L.ITEM_WILL_BE_SOLD, Colors.Red) or
      DCL:ColorString(L.ITEM_WILL_NOT_BE_SOLD, Colors.Green)
    sellRightText = DCL:ColorString(reasonText, DCL.CSS.White)
  end

  -- Destroy text
  if Tools:ItemCanBeDestroyed(item) then
    local isDestroyableItem, reasonText = Filters:Run(Destroyer, item)
    destroyLeftText =
      isDestroyableItem and
      DCL:ColorString(L.ITEM_WILL_BE_DESTROYED, Colors.Red) or
      DCL:ColorString(L.ITEM_WILL_NOT_BE_DESTROYED, Colors.Green)
    destroyRightText = DCL:ColorString(reasonText, DCL.CSS.White)
  end

  -- Add lines
  self:AddLine(" ") -- blank line
  self:AddLine(DCL:ColorString(AddonName, Colors.Primary))

  if sellLeftText then
    self:AddLine("  " .. sellLeftText)
    if sellRightText then self:AddLine("    " .. sellRightText) end
  end

  if destroyLeftText then
    self:AddLine("  " .. destroyLeftText)
    if destroyRightText then self:AddLine("    " .. destroyRightText) end
  end

  self:Show()
end)
