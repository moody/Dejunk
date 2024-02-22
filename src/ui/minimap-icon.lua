local ADDON_NAME, Addon = ...
local Actions = Addon:GetModule("Actions") --- @type Actions
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local LDB = Addon:GetLibrary("LDB")
local LDBIcon = Addon:GetLibrary("LDBIcon")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local StateManager = Addon:GetModule("StateManager") --- @type StateManager
local TickerManager = Addon:GetModule("TickerManager")

local function addDoubleLine(tooltip, leftLine, rightLine)
  tooltip:AddDoubleLine(Colors.Yellow(leftLine), Colors.White(rightLine))
end

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
        if IsShiftKeyDown() then Commands.destroy() else Commands.options() end
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Gold(Addon.VERSION))
      tooltip:AddLine(" ")
      addDoubleLine(tooltip, L.LEFT_CLICK, L.TOGGLE_JUNK_FRAME)
      addDoubleLine(tooltip, L.RIGHT_CLICK, L.TOGGLE_OPTIONS_FRAME)
      addDoubleLine(tooltip, Addon:Concat("+", L.SHIFT_KEY, L.LEFT_CLICK), L.START_SELLING)
      addDoubleLine(tooltip, Addon:Concat("+", L.SHIFT_KEY, L.RIGHT_CLICK), Colors.Red(L.DESTROY_NEXT_ITEM))
    end
  })

  local debouncePatchMinimapIcon
  do
    local patchCache = {}
    local patchTimer = TickerManager:NewTimer(0.2, function()
      StateManager:GetStore():Dispatch(Actions:PatchMinimapIcon(patchCache))
      for k in pairs(patchCache) do patchCache[k] = nil end
    end)
    patchTimer:Cancel() -- Prevent timer from executing immediately.

    --- Helper function to debounce a `PatchMinimapIcon` action.
    --- @param key string
    --- @param value any
    debouncePatchMinimapIcon = function(key, value)
      patchCache[key] = value
      patchTimer:Restart()
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
    LDBIcon:Refresh(ADDON_NAME)
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
