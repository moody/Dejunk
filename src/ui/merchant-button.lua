local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Locale
local SavedVariables = Addon.SavedVariables
local Sounds = Addon.Sounds
local Tooltip = Addon.Tooltip

EventManager:Once(E.SavedVariablesReady, function()
  local frame = CreateFrame("Button", ADDON_NAME .. "_MerchantButton", MerchantFrame, "OptionsButtonTemplate")
  frame:SetText(ADDON_NAME)
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  if Addon.IS_RETAIL then
    frame:SetPoint("TOPRIGHT", MerchantFrameLootFilter, "TOPLEFT", -4, 0)
  else
    frame:SetPoint("TOPLEFT", 60, -28)
  end

  MerchantFrame:HookScript("OnUpdate", function()
    if SavedVariables:Get().merchantButton then
      frame:Show()
    else
      frame:Hide()
    end
  end)

  frame:HookScript("OnUpdate", function(self)
    self:SetEnabled(not Addon:IsBusy())
  end)

  frame:HookScript("OnClick", function(self, button)
    if button == "LeftButton" then
      Sounds.Click()
      Commands.sell()
    end

    if button == "RightButton" then
      if IsShiftKeyDown() then
        Commands.options()
      else
        Commands.junk()
      end
    end
  end)

  frame:HookScript("OnEnter", function(self)
    Tooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    Tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Gold(Addon.VERSION))
    Tooltip:AddDoubleLine(L.LEFT_CLICK, L.START_SELLING)
    Tooltip:AddDoubleLine(L.RIGHT_CLICK, L.TOGGLE_JUNK_FRAME)
    Tooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME)
    Tooltip:Show()
  end)

  frame:HookScript("OnLeave", function()
    Tooltip:Hide()
  end)
end)
