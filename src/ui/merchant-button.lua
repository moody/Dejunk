local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Tooltip = Addon:GetModule("Tooltip")
local Widgets = Addon:GetModule("Widgets")

local junkItems = {}

EventManager:Once(E.Wow.MerchantShow, function()
  local frame = CreateFrame("Button", ADDON_NAME .. "_MerchantButton", MerchantFrame, "UIPanelButtonTemplate")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:SetText(ADDON_NAME)
  frame:SetWidth(90)
  frame:SetHeight(22)

  Widgets:ConfigureForDrag(frame)
  Widgets:ConfigureForPointSync(frame, "MerchantButton")

  -- MerchantFrame OnUpdate.
  MerchantFrame:HookScript("OnUpdate", function()
    if StateManager:GetGlobalState().merchantButton then frame:Show() else frame:Hide() end
  end)

  -- OnDragStart.
  frame:HookScript("OnDragStart", function()
    frame:GetScript("OnMouseUp")(frame)
    Tooltip:Hide()
  end)

  -- OnUpdate.
  frame:HookScript("OnUpdate", function(_, elapsed)
    frame:SetEnabled(not Addon:IsBusy())

    frame.delayTimer = (frame.delayTimer or 0.1) + elapsed
    if frame.delayTimer < 0.1 then return end
    frame.delayTimer = 0

    JunkFilter:GetSellableJunkItems(junkItems)
    frame:SetAlpha(#junkItems > 0 and 1 or 0.5)
  end)

  -- OnClick.
  frame:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
      if IsShiftKeyDown() then Commands.junk() else Commands.sell() end
    end

    if button == "RightButton" then
      if IsShiftKeyDown() then
        StateManager:GetStore():Dispatch(Actions:ResetMerchantButtonPoint())
      else
        Commands.options()
      end
    end
  end)

  -- OnEnter.
  frame:HookScript("OnEnter", function()
    Tooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
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
end)
