local AddonName, Addon = ...
local Colors = Addon.Colors
local Items = Addon.Items
local JunkFilter = Addon.JunkFilter
local L = Addon.Locale
local SavedVariables = Addon.SavedVariables

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
  if not SavedVariables:Get().itemTooltips or Items:IsBagSlotEmpty(bag, slot) then return end

  local item = Items:GetItem(bag, slot)
  if not item then return end

  local isJunk, reason = JunkFilter:IsJunkItem(item)
  if not reason then return end

  -- Add lines.
  self:AddLine(" ")
  self:AddLine(Colors.Blue(AddonName))
  self:AddLine("  " .. (isJunk and Colors.Red(L.ITEM_IS_JUNK) or Colors.Green(L.ITEM_IS_NOT_JUNK)))
  self:AddLine("  " .. Colors.Grey("- " .. Colors.White(reason)))

  self:Show()
end)
