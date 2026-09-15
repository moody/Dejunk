local Addon = select(2, ...) ---@type Addon
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class WindowTitleButtonWidget : FrameWidget, Button
--- @field texture Texture

--- @class WindowTitleButtonOptions
--- @field name string
--- @field texture string
--- @field textureSize? number
--- @field highlightColor Color
--- @field onClick fun()
--- @field onUpdateTooltip? fun(self: WindowTitleButtonWidget, tooltip: Tooltip)

-- =============================================================================
-- ComponentFactory - WindowTitleButton
-- =============================================================================

--- Creates a fixed-width icon button meant for a window's title row.
--- @param options WindowTitleButtonOptions
--- @return WaffleFlexComponent
function ComponentFactory:WindowTitleButton(options)
  return Addon.Waffle:Flex({
    width = 46,
    frameFactory = function(parent)
      --- @class WindowTitleButtonWidget : FrameWidget, Button
      local frame = Widgets:Frame({
        parent = parent,
        name = options.name,
        frameType = "Button",
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
      frame.texture:SetTexture(options.texture)
      frame.texture:SetSize(options.textureSize, options.textureSize)
      frame.texture:SetPoint("CENTER")

      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(options.highlightColor:GetRGBA(0.75)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
      frame:SetScript("OnClick", options.onClick)

      return frame
    end
  })
end
