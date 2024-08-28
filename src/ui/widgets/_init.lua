local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon

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
