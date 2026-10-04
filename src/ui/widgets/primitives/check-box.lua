local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CheckBoxWidgetOptions : FrameWidgetOptions
--- @field color? Color Defaults to `Colors.Blue`.
--- @field get fun(): boolean Returns whether the box is checked.

-- =============================================================================
-- Widgets - Check Box
-- =============================================================================

--- Creates a check box that only shows a value.
--- Mouse input passes through to the frame behind it.
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
  frame:EnableMouse(true)
  frame:SetPropagateMouseMotion(true)
  frame:SetPropagateMouseClicks(true)

  -- Check texture.
  frame.checkTexture = frame:CreateTexture("$parent_CheckTexture", "ARTWORK")
  frame.checkTexture:SetPoint("TOPLEFT", 2, -2)
  frame.checkTexture:SetPoint("BOTTOMRIGHT", -2, 2)

  -- Refresh on hover, enabled, show, and state changes.
  EventManager:WaitForFirst(E.StoreCreated, function()
    --- Updates the colors and check texture. Not highlighted while disabled.
    local function refresh()
      local isChecked = options.get()
      local isHovered = frame:GetEventValue("HOVERED") and frame:GetEventValue("ENABLED")
      local backdropColor = isChecked and options.color or Colors.DarkGrey
      frame:SetBackdropColor(backdropColor:GetRGBA(isHovered and 0.5 or 0.25))
      frame:SetBackdropBorderColor(options.color:GetRGBA(isHovered and 1 or 0.75))
      frame.checkTexture:SetColorTexture(options.color:GetRGBA(isHovered and 1 or 0.75))
      frame.checkTexture:SetShown(isChecked)
    end

    frame:OnEvent("HOVERED", refresh)
    frame:OnEvent("ENABLED", refresh)
    frame:HookScript("OnShow", refresh)
    EventManager:On(E.StateUpdated, function()
      if frame:IsVisible() then refresh() end
    end)

    refresh()
  end)

  return frame
end
