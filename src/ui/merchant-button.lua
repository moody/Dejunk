local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Tooltip = Addon:GetModule("Tooltip")
local Widgets = Addon:GetModule("Widgets")

local LABEL_TEXT_FORMAT = ("%s %s"):format(ADDON_NAME, Colors.Grey("(%s)"):format(Colors.White("%s")))

local junkItems = {}

-- ============================================================================
-- Initialize
-- ============================================================================

--- @class MerchantButtonWidget : ButtonWidget
local frame = Widgets:Button({
  name = ADDON_NAME .. "_MerchantButton",
  width = 100,
  labelText = LABEL_TEXT_FORMAT:format(0),
  labelColor = Colors.Blue,
  enableClickHandling = true,
  enableDragging = true
})

Widgets:ConfigureForPointSync(frame, "MerchantButton")

-- Click handlers.
frame:SetClickHandler("LeftButton", "NONE", Commands.sell)
frame:SetClickHandler("LeftButton", "SHIFT", Commands.junk)
frame:SetClickHandler("RightButton", "NONE", Commands.options)
frame:SetClickHandler("RightButton", "SHIFT", function()
  StateManager:Dispatch(Actions:ResetMerchantButtonPoint())
end)

-- OnUpdate.
frame:HookScript("OnUpdate", function(_, elapsed)
  frame:SetEnabled(not Addon:IsBusy())

  frame.delayTimer = (frame.delayTimer or 0.1) + elapsed
  if frame.delayTimer < 0.1 then return end
  frame.delayTimer = 0

  JunkFilter:GetSellableJunkItems(junkItems)
  frame.label:SetText(LABEL_TEXT_FORMAT:format(#junkItems))
end)

-- OnEnter.
frame:HookScript("OnEnter", function()
  Tooltip:SetOwner(frame, "ANCHOR_RIGHT")
  Tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Grey(Addon.VERSION))
  Tooltip:AddLine(Addon:SubjectDescription(L.LEFT_CLICK, L.START_SELLING))
  Tooltip:AddLine(Addon:SubjectDescription(L.RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME))
  Tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.SHIFT_KEY, L.LEFT_CLICK), L.TOGGLE_JUNK_FRAME))
  Tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.SHIFT_KEY, L.RIGHT_CLICK), L.RESET_POSITION))
  Tooltip:Show()
end)

-- OnLeave.
frame:HookScript("OnLeave", function()
  Tooltip:Hide()
end)

-- OnDragStart.
frame:HookScript("OnDragStart", function()
  frame:GetScript("OnLeave")(frame)
end)

-- OnDragStop.
frame:HookScript("OnDragStop", function()
  if frame:IsMouseOver() then
    frame:GetScript("OnEnter")(frame)
  end
end)

-- ============================================================================
-- Ticker to update visibility.
-- ============================================================================

TickerManager:NewTicker(0.01, function()
  if MerchantFrame and MerchantFrame:IsShown() and StateManager:GetGlobalState().merchantButton then
    frame:Show()
  else
    frame:Hide()
  end
end)
