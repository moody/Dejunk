local AddonName, Addon = ...
local Core = Addon.Core
local DB = Addon.DB
local Dejunker = Addon.Dejunker
local DTL = Addon.Libs.DTL
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Libs.L
local MerchantButton = Addon.UI.MerchantButton
local UI = Addon.UI

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.DatabaseReady, function()
  local button = _G.CreateFrame(
    "Button",
    AddonName .. "MerchantButton",
    _G.MerchantFrame,
    "OptionsButtonTemplate"
  )
  button:SetText(AddonName)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  -- Skin & position button for ElvUI if necessary
  local ElvUI = _G.ElvUI and _G.ElvUI[1] -- ElvUI Engine
  if
    ElvUI and
    ElvUI.private.skins.blizzard.enable and
    ElvUI.private.skins.blizzard.merchant
  then
    ElvUI:GetModule("Skins"):HandleButton(button)
    if Addon.IS_RETAIL then
      button:SetPoint("TOPLEFT", 11, -28)
    else
      button:SetPoint("BOTTOMLEFT", _G.MerchantItem1, "TOPLEFT", 0, 8)
    end
  else
    if Addon.IS_RETAIL then
      button:SetPoint("TOPRIGHT", _G.MerchantFrameLootFilter, "TOPLEFT", -4, 0)
    else
      button:SetPoint("TOPLEFT", 60, -28)
    end
  end

  -- Scripts
  button:HookScript("OnUpdate", function(self)
    self:SetEnabled(Core:CanDejunk())
  end)

  button:HookScript("OnClick", function(self, mouseButton)
    if (mouseButton == "LeftButton") then
      Dejunker:Start()
    elseif (mouseButton == "RightButton") then
      UI:Toggle()
    end
  end)

  button:HookScript("OnEnter", function(self)
    DTL:ShowTooltip(
      self,
      "ANCHOR_RIGHT",
      self:GetText(),
      L.DEJUNK_BUTTON_TOOLTIP
    )
  end)

  button:HookScript("OnLeave", function()
    DTL:HideTooltip()
  end)

  -- Add to MerchantButton + update
  MerchantButton.button = button
  MerchantButton:Update()
end)

-- ============================================================================
-- Functions
-- ============================================================================

function MerchantButton:Update()
  if DB.Global.MerchantButton then
    self.button:Show()
  else
    self.button:Hide()
  end
end
