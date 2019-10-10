-- MerchantButton: displays a "Dejunk" button on the merchant frame.

local AddonName, Addon = ...
local Core = Addon.Core
local Dejunker = Addon.Dejunker
local DTL = Addon.Libs.DTL
local L = Addon.Libs.L
local MerchantButton = Addon.MerchantButton
local UI = Addon.UI

-- ============================================================================
-- Merchant Button
-- ============================================================================

-- Initializes the frame.
function MerchantButton:Initialize()
  self.Button = _G.CreateFrame(
    "Button",
    AddonName .. "MerchantButton",
    _G.MerchantFrame,
    "OptionsButtonTemplate"
  )
  self.Button:SetText(AddonName)

  -- Skin & position button for ElvUI if necessary
  local E = _G["ElvUI"] and _G["ElvUI"][1] -- ElvUI Engine
  if E and E.private.skins.blizzard.enable and E.private.skins.blizzard.merchant then
    E:GetModule("Skins"):HandleButton(self.Button)
    if Addon.IS_RETAIL then
      self.Button:SetPoint("TOPLEFT", 11, -28)
    else
      self.Button:SetPoint("BOTTOMLEFT", _G.MerchantItem1, "TOPLEFT", 0, 8)
    end
  else
    if Addon.IS_RETAIL then
      self.Button:SetPoint("TOPRIGHT", _G.MerchantFrameLootFilter, "TOPLEFT", -4, 0)
    else
      self.Button:SetPoint("TOPLEFT", 60, -28)
    end
  end

  self.Button:HookScript("OnUpdate", function(self, elapsed)
    self:SetEnabled(Core:CanDejunk())
  end)

  self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self.Button:HookScript("OnClick", function(self, button, down)
    if (button == "LeftButton") then
      Dejunker:StartDejunking()
    elseif (button == "RightButton") then
      UI:Toggle()
    end
  end)

  self.Button:HookScript("OnEnter", function(self)
    DTL:ShowTooltip(self, "ANCHOR_RIGHT", self:GetText(), L.DEJUNK_BUTTON_TOOLTIP)
  end)
  self.Button:HookScript("OnLeave", DTL.HideTooltip)

  -- nil function
  self.Initialize = nil
end
