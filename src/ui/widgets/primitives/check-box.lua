local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CheckBoxWidgetOptions : FrameWidgetOptions
--- @field color? Color Defaults to `Colors.Blue`.

-- =============================================================================
-- Widgets - Check Box
-- =============================================================================

--- Creates a check box that only shows a state, and does not take the mouse.
--- Its owner sets whether it is checked with `SetChecked()`, and fires `HOVERED` on it to highlight it.
--- @param options CheckBoxWidgetOptions
--- @return CheckBoxWidget frame
function Widgets:CheckBox(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("CheckBox"))
  options.width = Addon:IfNil(options.width, 20)
  options.height = Addon:IfNil(options.height, 20)
  options.color = Addon:IfNil(options.color, Colors.Blue)

  --- @class CheckBoxWidget : FrameWidget
  local frame = self:Frame(options)
  frame.isChecked = false

  -- Check texture.
  frame.checkTexture = frame:CreateTexture("$parent_CheckTexture", "ARTWORK")
  frame.checkTexture:SetPoint("TOPLEFT", 2, -2)
  frame.checkTexture:SetPoint("BOTTOMRIGHT", -2, 2)

  --- Updates the colors and check texture. Not highlighted while disabled.
  local function refresh()
    local isHovered = frame:GetEventValue("HOVERED") and frame:GetEventValue("ENABLED")
    local backdropColor = frame.isChecked and options.color or Colors.DarkGrey
    frame:SetBackdropColor(backdropColor:GetRGBA(isHovered and 0.5 or 0.25))
    frame:SetBackdropBorderColor(options.color:GetRGBA(isHovered and 1 or 0.75))
    frame.checkTexture:SetColorTexture(options.color:GetRGBA(isHovered and 1 or 0.75))
    frame.checkTexture:SetShown(frame.isChecked)
  end
  frame:OnEvent("HOVERED", refresh)
  frame:OnEvent("ENABLED", refresh)

  -- Never take the mouse, even after listening for `HOVERED`.
  frame:EnableMouse(false)

  --- Sets whether the box is checked.
  --- @param checked boolean
  function frame:SetChecked(checked)
    self.isChecked = checked
    refresh()
  end

  return frame
end
