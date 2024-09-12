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

local junkItems = {}

EventManager:Once(E.Wow.MerchantShow, function()
  local frame = CreateFrame("Button", ADDON_NAME .. "_MerchantButton", MerchantFrame, "UIPanelButtonTemplate")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:SetText(ADDON_NAME)
  frame:SetWidth(90)
  frame:SetHeight(22)

  frame:SetFrameStrata("HIGH")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")

  -- MerchantFrame OnUpdate.
  MerchantFrame:HookScript("OnUpdate", function()
    if StateManager:GetGlobalState().merchantButton then frame:Show() else frame:Hide() end
  end)

  do -- Refresh the frame's point on certain events.
    local function refreshPoint()
      local state = StateManager:GetGlobalState().points.merchantButton
      frame:ClearAllPoints()
      frame:SetPoint(state.point, nil, state.relativePoint, state.offsetX, state.offsetY)
    end

    EventManager:On(E.StateUpdated, refreshPoint)
    frame:SetScript("OnShow", refreshPoint)
  end

  -- OnDragStart.
  frame:SetScript("OnDragStart", function()
    frame:StartMoving(true)
    frame:GetScript("OnMouseUp")(frame)
    Tooltip:Hide()
  end)

  -- OnDragStop.
  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()

    local point, _, relativePoint, offsetX, offsetY = frame:GetPoint()
    StateManager:GetStore():Dispatch(Actions:SetMerchantButtonPoint({
      point = point,
      relativePoint = relativePoint,
      offsetX = offsetX,
      offsetY = offsetY
    }))
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
      Commands.sell()
    end

    if button == "RightButton" then
      if IsShiftKeyDown() then
        StateManager:GetStore():Dispatch(Actions:ResetMerchantButtonPoint())
      else
        Commands.junk()
      end
    end
  end)

  -- OnEnter.
  frame:HookScript("OnEnter", function()
    Tooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
    Tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Grey(Addon.VERSION))
    Tooltip:AddLine(Addon:SubjectDescription(L.LEFT_CLICK, L.START_SELLING))
    Tooltip:AddLine(Addon:SubjectDescription(L.RIGHT_CLICK, L.TOGGLE_JUNK_FRAME))
    Tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.SHIFT_KEY, L.RIGHT_CLICK), L.RESET_POSITION))
    Tooltip:Show()
  end)

  -- OnLeave.
  frame:HookScript("OnLeave", function()
    Tooltip:Hide()
  end)
end)
