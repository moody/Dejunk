local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local LDB = Addon:GetLibrary("LDB") ---@type LibDataBroker-1.1
local LDBIcon = Addon:GetLibrary("LDBIcon") ---@type LibDBIcon-1.0
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Tooltip = Addon:GetModule("Tooltip")

--- @class MinimapIcon
local MinimapIcon = Addon:GetModule("MinimapIcon")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Ripped from LibDBIcon to keep tooltip positioning behavior consistent.
local function getAnchors(frame)
  local x, y = frame:GetCenter()
  if not x or not y then return "CENTER" end
  local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
  local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
  return vhalf .. hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP") .. hhalf
end

--- @param frame Frame
local function onUpdateTooltip(frame)
  Tooltip:ClearLines()

  if IsAltKeyDown() then
    local item = JunkFilter:GetNextDestroyableJunkItem()
    if item then
      Tooltip:SetBagItem(item.bag, item.slot)
      Tooltip:AddLine(" ")
      Tooltip:AddDoubleLine(L.RIGHT_CLICK, Colors.Red(L.DESTROY))
      Tooltip:Show()
      return
    end
  end

  Tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Grey(Addon.VERSION))
  Tooltip:AddLine(Addon:SubjectDescription(L.LEFT_CLICK, L.TOGGLE_JUNK_FRAME))
  Tooltip:AddLine(Addon:SubjectDescription(L.RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME))
  Tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.SHIFT_KEY, L.LEFT_CLICK), L.START_SELLING))
  Tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.ALT_KEY, L.RIGHT_CLICK), Colors.Red(L.DESTROY_NEXT_ITEM)))
  Tooltip:Show()
end

-- =============================================================================
-- LibDBIcon
-- =============================================================================

EventManager:Once(E.StoreCreated, function()
  local object = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = ADDON_NAME,
    icon = Addon:GetAsset("dejunk-icon"),

    OnClick = function(_, button)
      if button == "LeftButton" then
        if IsShiftKeyDown() then Commands.sell() else Commands.junk() end
      end

      if button == "RightButton" then
        if IsAltKeyDown() then Commands.destroy() else Commands.options() end
      end
    end,

    --- @param frame Frame|any
    OnEnter = function(frame)
      -- Tooltip will repeatedly call `UpdateTooltip()` on the frame when passed to `SetOwner()`.
      Tooltip:SetOwner(frame, "ANCHOR_NONE")
      Tooltip:SetPoint(getAnchors(frame))
      frame.UpdateTooltip = onUpdateTooltip
      frame:UpdateTooltip()
    end,

    OnLeave = function()
      Tooltip:Hide()
    end,
  })

  local debouncePatchMinimapIcon
  do
    local patchCache = {}
    local debounce = TickerManager:NewDebouncer(0.2, function()
      StateManager:GetStore():Dispatch(Actions:PatchMinimapIcon(patchCache))
      for k in pairs(patchCache) do patchCache[k] = nil end
    end)

    --- Helper function to debounce a `PatchMinimapIcon` action.
    --- @param key string
    --- @param value any
    debouncePatchMinimapIcon = function(key, value)
      patchCache[key] = value
      debounce()
    end
  end

  -- When the minimap icon is being dragged, LibDBIcon sets `db.minimapPos` on every frame update.
  -- Therefore, we use a metatable to debounce changes.
  local db = setmetatable({}, {
    __index = function(t, k)
      return StateManager:GetGlobalState().minimapIcon[k]
    end,
    __newindex = function(t, k, v)
      debouncePatchMinimapIcon(k, v)
    end
  })

  LDBIcon:Register(ADDON_NAME, object, db)

  -- Listen for the `StateUpdated` event and refresh the icon.
  EventManager:On(E.StateUpdated, function()
    LDBIcon:Refresh(ADDON_NAME, db)
  end)

  --- Returns true if the minimap icon is visible.
  --- @return boolean
  function MinimapIcon:IsEnabled()
    return not StateManager:GetGlobalState().minimapIcon.hide
  end

  --- Sets the visibility of the minimap icon.
  --- @param enabled boolean
  function MinimapIcon:SetEnabled(enabled)
    StateManager:GetStore():Dispatch(Actions:PatchMinimapIcon({ hide = not enabled }))
  end
end)
