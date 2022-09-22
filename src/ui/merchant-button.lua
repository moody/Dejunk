local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Locale
local Lists = Addon.Lists
local SavedVariables = Addon.SavedVariables
local Seller = Addon.Seller
local UserInterface = Addon.UserInterface

EventManager:Once(E.SavedVariablesReady, function()
  local button = CreateFrame("Button", ADDON_NAME .. "_MerchantButton", MerchantFrame, "OptionsButtonTemplate")
  button:SetText(ADDON_NAME)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  if Addon.IS_RETAIL then
    button:SetPoint("TOPRIGHT", MerchantFrameLootFilter, "TOPLEFT", -4, 0)
  else
    button:SetPoint("TOPLEFT", 60, -28)
  end

  MerchantFrame:HookScript("OnUpdate", function()
    if SavedVariables:Get().merchantButton then
      button:Show()
    else
      button:Hide()
    end
  end)

  button:HookScript("OnUpdate", function(self)
    local enabled = not (Lists:IsBusy() or Seller:IsBusy())
    self:SetEnabled(enabled)
  end)

  button:HookScript("OnClick", function(self, b)
    if b == "LeftButton" then
      Seller:Start()
    elseif b == "RightButton" then
      UserInterface:Toggle()
    end
  end)

  button:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Addon.VERSION)
    GameTooltip:AddDoubleLine(L.LEFT_CLICK, Colors.White(L.START_SELLING))
    GameTooltip:AddDoubleLine(L.RIGHT_CLICK, Colors.White(L.TOGGLE_USER_INTERFACE))
    GameTooltip:Show()
  end)

  button:HookScript("OnLeave", function()
    GameTooltip:Hide()
  end)
end)
