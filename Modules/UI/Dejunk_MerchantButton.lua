-- Dejunk_MerchantButton: displays a "Dejunk" button on the merchant frame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local MerchantButton = DJ.MerchantButton

local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local Dejunker = DJ.Dejunker
local Repairer = DJ.Repairer
local ListManager = DJ.ListManager

-- Variables
MerchantButton.Initialized = false

-- ============================================================================
--                               Merchant Button
-- ============================================================================

-- Initializes the frame.
function MerchantButton:Initialize()
  if self.Initialized then return end

  self.Button = CreateFrame("Button", (AddonName.."MerchantButton"), MerchantFrame, "OptionsButtonTemplate")
  self.Button:SetText(L.DEJUNK_TEXT)

  -- Skin & position button for ElvUI if necessary
  local E = _G["ElvUI"] and _G["ElvUI"][1] -- ElvUI Engine
  if E and E.private.skins.blizzard.enable and E.private.skins.blizzard.merchant then
    E:GetModule("Skins"):HandleButton(self.Button)
    self.Button:SetPoint("TOPLEFT", 11, -28)
  else
    self.Button:SetPoint("TOPRIGHT", MerchantFrameLootFilter, "TOPLEFT", -4, 0)
  end

  self.Button:HookScript("OnUpdate", function(self, elapsed)
    self:SetEnabled(DJ.Core:CanDejunk())
  end)

  self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self.Button:HookScript("OnClick", function(self, button, down)
    if (button == "LeftButton") then
      Dejunker:StartDejunking()
    elseif (button == "RightButton") then
      DJ.Core:ToggleGUI()
    end
  end)

  self.Button:HookScript("OnEnter", function(self)
    Tools:ShowTooltip(self, "ANCHOR_RIGHT",
      self:GetText(), L.DEJUNK_BUTTON_TOOLTIP)
  end)

  self.Button:HookScript("OnLeave", function(self)
    Tools:HideTooltip() end)

  self.Initialized = true
end

-- ============================================================================
--                             Merchant Frame Hook
-- ============================================================================

MerchantFrame:HookScript("OnShow", function()
  if DejunkDB.SV.AutoSell then
    Dejunker:StartDejunking() end

  if DejunkDB.SV.AutoRepair then
    Repairer:StartRepairing() end
end)

MerchantFrame:HookScript("OnHide", function()
  if Dejunker:IsSelling() then
    Dejunker:StopSelling() end

  if Repairer:IsRepairing() then
    Repairer:StopRepairing() end
end)
