local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

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

--- @class ConfigureForPointSyncOptions
--- @field frame ScriptRegion
--- @field getPoint fun(): table Returns the point to apply.
--- @field setPoint fun(point: table) Called with the point to save after dragging.

--- Configures a draggable frame to refresh or save its point based on certain events.
--- @param options ConfigureForPointSyncOptions
function Widgets:ConfigureForPointSync(options)
  local frame = options.frame

  local function refresh()
    local p = options.getPoint()
    local relativeTo = p.relativeTo and _G[p.relativeTo] or UIParent
    frame:ClearAllPoints()
    frame:SetPoint(p.point, relativeTo, p.relativePoint, p.offsetX, p.offsetY)
  end

  local function save()
    local parent = frame:GetParent() or UIParent
    options.setPoint({
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
