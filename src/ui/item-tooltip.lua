local AddonName, Addon = ...
local Bags = Addon.Bags
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local Filters = Addon.Filters
local L = Addon.Libs.L

local item = {}

_G.hooksecurefunc(_G.GameTooltip, "SetBagItem", function(self, bag, slot)
  if not DB.Global.showItemTooltip or Bags:IsEmpty(bag, slot) then return end
  if not Bags:GetItem(bag, slot, item) then return end

  local sellLeftText, sellRightText do
    local isJunk, reason = Filters:Run(Dejunker, item)
    if reason then
      sellLeftText =
        isJunk and
        DCL:ColorString(L.ITEM_WILL_BE_SOLD, Colors.Red) or
        DCL:ColorString(L.ITEM_WILL_NOT_BE_SOLD, Colors.Green)

      sellRightText = DCL:ColorString(reason, DCL.CSS.White)
    end
  end

  local destroyLeftText, destroyRightText do
    local isJunk, reason = Filters:Run(Destroyer, item)
    if reason then
      destroyLeftText =
        isJunk and
        DCL:ColorString(L.ITEM_WILL_BE_DESTROYED, Colors.Red) or
        DCL:ColorString(L.ITEM_WILL_NOT_BE_DESTROYED, Colors.Green)

      destroyRightText = DCL:ColorString(reason, DCL.CSS.White)
    end
  end

  -- Exit early if no text to display
  if not (sellLeftText or destroyLeftText) then return end

  -- Add lines
  self:AddLine(" ") -- blank line
  self:AddLine(DCL:ColorString(AddonName, Colors.Primary))

  if sellLeftText then
    self:AddLine("  " .. sellLeftText)
    self:AddLine("    " .. sellRightText)
  end

  if destroyLeftText then
    self:AddLine("  " .. destroyLeftText)
    self:AddLine("    " .. destroyRightText)
  end

  self:Show()
end)
