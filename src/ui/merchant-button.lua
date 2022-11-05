local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Locale
local SavedVariables = Addon.SavedVariables
local Tooltip = Addon.Tooltip

EventManager:Once(E.Wow.MerchantShow, function()
  local frame = CreateFrame("Button", ADDON_NAME .. "_MerchantButton", MerchantFrame, "UIPanelButtonTemplate")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:SetText(ADDON_NAME)
  frame:SetWidth(90)
  frame:SetHeight(22)
  frame:SetPoint("TOPLEFT", 60, -28)

  -- Skin for ElvUI.
  pcall(function(frame)
    local E = ElvUI[1]
    local S = E:GetModule("Skins")
    if E.private.skins.blizzard.enable and E.private.skins.blizzard.merchant then
      S:HandleButton(frame)
      frame:SetPoint("TOPLEFT", 4, -4)
    end
  end, frame)

  MerchantFrame:HookScript("OnUpdate", function()
    if SavedVariables:Get().merchantButton then frame:Show() else frame:Hide() end
  end)

  frame:HookScript("OnUpdate", function(self)
    self:SetEnabled(not Addon:IsBusy())
  end)

  frame:HookScript("OnClick", function(self, button)
    if button == "LeftButton" then
      if IsShiftKeyDown() then Commands.sell() else Commands.junk() end
    end

    if button == "RightButton" then
      if IsShiftKeyDown() then Commands.destroy() else Commands.options() end
    end
  end)

  frame:HookScript("OnEnter", function(self)
    Tooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    Tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Gold(Addon.VERSION))
    Tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_JUNK_FRAME)
    Tooltip:AddDoubleLine(L.RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME)
    Tooltip:AddDoubleLine(L.SHIFT_LEFT_CLICK, L.START_SELLING)
    Tooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, L.DESTROY_NEXT_ITEM)
    Tooltip:Show()
  end)

  frame:HookScript("OnLeave", function()
    Tooltip:Hide()
  end)
end)
