-- MerchantButton: displays a "Dejunk" button on the merchant frame.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DTL = Addon.Libs.DTL

-- Modules
local MerchantButton = Addon.MerchantButton

local Core = Addon.Core
local DejunkDB = Addon.DejunkDB
local Dejunker = Addon.Dejunker
local Repairer = Addon.Repairer

-- ============================================================================
-- Merchant Button
-- ============================================================================

-- Initializes the frame.
function MerchantButton:Initialize()
  self.Button = CreateFrame("Button", (AddonName.."MerchantButton"), MerchantFrame, "OptionsButtonTemplate")
  self.Button:SetText(AddonName)

  -- Skin & position button for ElvUI if necessary
  local E = _G["ElvUI"] and _G["ElvUI"][1] -- ElvUI Engine
  if E and E.private.skins.blizzard.enable and E.private.skins.blizzard.merchant then
    E:GetModule("Skins"):HandleButton(self.Button)
    self.Button:SetPoint("TOPLEFT", 11, -28)
  else
    self.Button:SetPoint("TOPRIGHT", MerchantFrameLootFilter, "TOPLEFT", -4, 0)
  end

  self.Button:HookScript("OnUpdate", function(self, elapsed)
    self:SetEnabled(Core:CanDejunk())
  end)

  self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self.Button:HookScript("OnClick", function(self, button, down)
    if (button == "LeftButton") then
      Dejunker:StartDejunking()
    elseif (button == "RightButton") then
      Core:ToggleGUI()
    end
  end)

  self.Button:HookScript("OnEnter", function(self)
    DTL:ShowTooltip(self, "ANCHOR_RIGHT", self:GetText(), L.DEJUNK_BUTTON_TOOLTIP)
  end)
  self.Button:HookScript("OnLeave", DTL.HideTooltip)

  -- nil function
  self.Initialize = nil
end

-- ============================================================================
--                             Merchant Frame Hook
-- ============================================================================

MerchantFrame:HookScript("OnShow", function()
  if DejunkDB.SV.AutoSell then Dejunker:StartDejunking(true) end
  if DejunkDB.SV.AutoRepair then Repairer:StartRepairing() end
end)

MerchantFrame:HookScript("OnHide", function()
  if Dejunker:IsSelling() then Dejunker:StopSelling() end
  if Repairer:IsRepairing() then Repairer:StopRepairing() end
end)
