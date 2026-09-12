local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local StateManager = Addon:GetModule("StateManager")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

Widgets.BORDER_BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  tileEdge = false,
  edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

do -- Widget:Padding()
  local PADDING = 8
  local cache = {}

  --- Returns a base padding of `8` multiplied by the given number.
  --- @param multiplier? number
  --- @return number padding
  function Widgets:Padding(multiplier)
    if type(multiplier) ~= "number" then return PADDING end
    local value = cache[tostring(multiplier)]
    if not value then
      value = PADDING * multiplier
      cache[tostring(multiplier)] = value
    end
    return value
  end
end

do -- Widget:GetUniqueName()
  local ids = {}

  --- Returns a unique variant of the given `widgetName`.
  --- @param widgetName string
  --- @return string
  function Widgets:GetUniqueName(widgetName)
    ids[widgetName] = (ids[widgetName] or 0) + 1
    return ("%s_%s%s"):format(ADDON_NAME, widgetName, ids[widgetName])
  end
end

--- Configures a draggable `frame` to refresh or save its point based on certain events.
--- @param frame Frame | any
--- @param stateType "MainWindow" | "JunkFrame" | "TransportFrame" | "MerchantButton"
function Widgets:ConfigureForPointSync(frame, stateType)
  local getPoint, setPoint

  if stateType == "MainWindow" then
    getPoint = function() return StateManager:GetGlobalState().points.mainWindow end
    setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.mainWindow.set(point)) end
  elseif stateType == "JunkFrame" then
    getPoint = function() return StateManager:GetGlobalState().points.junkFrame end
    setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.junkFrame.set(point)) end
  elseif stateType == "TransportFrame" then
    getPoint = function() return StateManager:GetGlobalState().points.transportFrame end
    setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.transportFrame.set(point)) end
  elseif stateType == "MerchantButton" then
    getPoint = function()
      local point = StateManager:GetGlobalState().points.merchantButton
      return (point.relativeTo ~= DefaultStates.Global.points.merchantButton.relativeTo) and
          DefaultStates.Global.points.merchantButton or
          point
    end
    setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.merchantButton.set(point)) end
  end

  local function refresh()
    local p = getPoint()
    local relativeTo = p.relativeTo and _G[p.relativeTo] or UIParent
    frame:ClearAllPoints()
    frame:SetPoint(p.point, relativeTo, p.relativePoint, p.offsetX, p.offsetY)
  end

  local function save()
    local parent = frame:GetParent() or UIParent
    setPoint({
      point = "TOPLEFT",
      relativeTo = parent:GetName(),
      relativePoint = "TOPLEFT",
      offsetX = frame:GetLeft() - parent:GetLeft(),
      offsetY = frame:GetTop() - parent:GetTop()
    })
  end

  EventManager:On(E.StateUpdated, refresh)
  frame:HookScript("OnShow", refresh)
  frame:HookScript("OnDragStop", save)
end

--- Returns the width and height `fontString`'s current text actually
--- needs, ignoring any existing `SetWidth()`/`SetHeight()` constraint.
--- Not a cheap read: briefly resizes `fontString` to measure it before
--- restoring its previous size, avoid calling more than once per text
--- change.
--- @param fontString FontString
--- @return number width, number height
function Widgets:MeasureFontStringSize(fontString)
  local prevWidth = fontString:GetStringWidth()
  local prevHeight = fontString:GetStringHeight()

  -- Get new sizes.
  fontString:SetTextToFit(fontString:GetText())
  local newWidth = fontString:GetStringWidth()
  local newHeight = fontString:GetStringHeight()

  -- Restore.
  fontString:SetSize(prevWidth, prevHeight)

  return newWidth, newHeight
end
