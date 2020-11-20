local AddonName, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local Core = Addon.Core
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local E = Addon.Events
local EventManager = Addon.EventManager
local GameTooltip = _G.GameTooltip
local IsShiftKeyDown = _G.IsShiftKeyDown
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
      if IsShiftKeyDown() then Commands.sell() else Dejunker:Start() end
    elseif (mouseButton == "RightButton") then
      if IsShiftKeyDown() then Commands.destroy() else UI:Toggle() end
    end
  end)

  button:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddDoubleLine(
      DCL:ColorString(AddonName, Colors.Primary),
      Addon.VERSION
    )
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L.LEFT_CLICK, L.START_SELLING_BUTTON_TEXT, nil, nil, nil, 1, 1, 1)
    GameTooltip:AddDoubleLine(L.RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME, nil, nil, nil, 1, 1, 1)
    GameTooltip:AddDoubleLine(L.SHIFT_LEFT_CLICK, L.TOGGLE_SELL_FRAME, nil, nil, nil, 1, 1, 1)
    GameTooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, L.TOGGLE_DESTROY_FRAME, nil, nil, nil, 1, 1, 1)
    GameTooltip:Show()
  end)

  button:HookScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Add to MerchantButton + update
  MerchantButton.button = button
  MerchantButton:Update()
end)

-- ============================================================================
-- Functions
-- ============================================================================

function MerchantButton:Update()
  if DB.Global.showMerchantButton then
    self.button:Show()
  else
    self.button:Hide()
  end
end
