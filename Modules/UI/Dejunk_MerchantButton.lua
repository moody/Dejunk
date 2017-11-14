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

--[[
//*******************************************************************
//                          Merchant Button
//*******************************************************************
--]]

-- Initializes the frame.
function MerchantButton:Initialize()
  if self.Initialized then return end

  self.Button = CreateFrame("Button", (AddonName.."MerchantButton"), MerchantFrame, "OptionsButtonTemplate")
  self.Button:SetPoint("TOPRIGHT", MerchantFrameLootFilter, "TOPLEFT", -4, 0)
  self.Button:SetText(L.DEJUNK_TEXT)

  self.Button:SetScript("OnUpdate", function(self, elapsed)
    self:SetEnabled(DJ.Core:CanDejunk())
  end)

  self.Button:SetScript("OnShow", function(self)
    if DejunkDB.SV.AutoSell then
      Dejunker:StartDejunking() end

    if DejunkDB.SV.AutoRepair then
      Repairer:StartRepairing() end
  end)

  self.Button:SetScript("OnHide", function(self)
    if Dejunker:IsSelling() then
      Dejunker:StopSelling() end

    if Repairer:IsRepairing() then
      Repairer:StopRepairing() end
  end)

  self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  self.Button:SetScript("OnClick", function(self, button, down)
    if (button == "LeftButton") then
      Dejunker:StartDejunking()
    elseif (button == "RightButton") then
      DJ.Core:ToggleGUI()
    end
  end)

  self.Button:SetScript("OnEnter", function(self)
    Tools:ShowTooltip(self, "ANCHOR_RIGHT",
      self:GetText(), L.DEJUNK_BUTTON_TOOLTIP)
  end)

  self.Button:SetScript("OnLeave", function(self)
    Tools:HideTooltip() end)

  self.Initialized = true
end
