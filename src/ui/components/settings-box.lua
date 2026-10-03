local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- Height of one row of controls, so each label centers on a line's first row.
local CONTROL_HEIGHT = 24

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SettingsBoxComponentOptions
--- @field labelWidth? integer Width of each line's label. Defaults to `80`.
--- @field isEnabled? fun(): boolean Dims the lines while it returns `false`.

-- =============================================================================
-- ComponentFactory - SettingsBox
-- =============================================================================

--- Creates a column of labeled lines.
--- @param options? SettingsBoxComponentOptions
--- @return SettingsBoxComponent root
function ComponentFactory:SettingsBox(options)
  local labelWidth = options and options.labelWidth or 80

  --- @class SettingsBoxComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "COLUMN",
    height = "AUTO",
    gap = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = CreateFrame("Frame", nil, parent)

      if options and options.isEnabled then
        local function refresh() frame:SetAlpha(options.isEnabled() and 1 or 0.5) end
        refresh()
        EventManager:On(E.StateUpdated, refresh)
      end

      return frame
    end
  })

  --- Adds a line with the given label, returning the row its controls go into.
  --- @param labelText string
  --- @return WaffleFlexComponent line
  function root:AddLine(labelText)
    local line = self:AddRow({ height = "AUTO", align = "START", gap = Widgets:Padding() })
    line:AttachComponent(ComponentFactory:Text({
      text = labelText,
      fontObject = "GameFontNormalSmall",
      color = Colors.Grey,
      wordWrap = false,
      width = labelWidth,
      minHeight = CONTROL_HEIGHT
    }))
    return line
  end

  return root
end
