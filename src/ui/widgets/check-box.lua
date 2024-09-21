local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CheckBoxWidgetOptions : FrameWidgetOptions
--- @field color? Color
--- @field get fun(): boolean
--- @field set fun(value: boolean): nil

-- =============================================================================
-- Widgets - Check Box
-- =============================================================================

--- Creates a check box.
--- @param options CheckBoxWidgetOptions
--- @return CheckBoxWidget frame
function Widgets:CheckBox(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("CheckBox"))
  options.width = Addon:IfNil(options.width, 20)
  options.height = Addon:IfNil(options.height, 20)
  options.color = Addon:IfNil(options.color, Colors.Blue)
  options.enableClickHandling = true

  --- @class CheckBoxWidget : FrameWidget
  local frame = self:Frame(options)

  local function setNormalColors(isEnabled)
    if isEnabled then
      frame:SetBackdropColor(options.color:GetRGBA(0.25))
      frame:SetBackdropBorderColor(options.color:GetRGBA(0.75))
    else
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    end
  end

  local function setHighlightColors(isEnabled)
    if isEnabled then
      frame:SetBackdropColor(options.color:GetRGBA(0.5))
      frame:SetBackdropBorderColor(options.color:GetRGBA(1))
    else
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
    end
  end

  frame:SetClickHandler("LeftButton", "NONE", function()
    options.set(not options.get())
  end)

  frame:HookScript("OnUpdate", function()
    local isEnabled = options.get()

    if frame:IsMouseOver() then
      setHighlightColors(isEnabled)
    else
      setNormalColors(isEnabled)
    end
  end)

  return frame
end
