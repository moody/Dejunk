local Addon = select(2, ...) ---@type Addon
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class IconButtonComponentOptions
--- @field name? string Global frame name. Defaults to a unique name.
--- @field icon string Texture of the icon.
--- @field iconSize? number Defaults to `14`.
--- @field width? number Defaults to `46`.
--- @field highlightColor Color Fill color while hovered.
--- @field onClick fun() Called when the button is clicked.
--- @field onUpdateTooltip? fun(self: IconButtonWidget, tooltip: Tooltip) Shown while hovering the button.

-- =============================================================================
-- ComponentFactory - IconButton
-- =============================================================================

--- Creates a fixed-width button with an icon.
--- @param options IconButtonComponentOptions
--- @return IconButtonComponent
function ComponentFactory:IconButton(options)
  --- @class IconButtonComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    width = options.width or 46,
    frameFactory = function(parent)
      --- @class IconButtonWidget : FrameWidget, Button
      local frame = Widgets:Frame({
        parent = parent,
        name = options.name,
        frameType = "Button",
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      local iconSize = options.iconSize or 14
      frame.icon = frame:CreateTexture("$parent_Icon", "ARTWORK")
      frame.icon:SetTexture(options.icon)
      frame.icon:SetSize(iconSize, iconSize)
      frame.icon:SetPoint("CENTER")

      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(options.highlightColor:GetRGBA(0.75)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
      frame:SetScript("OnClick", options.onClick)

      return frame
    end
  })

  --- Sets the icon's texture.
  --- @param icon string
  function root:SetIcon(icon)
    self:WhenFrameReady(function(frame)
      frame.icon:SetTexture(icon)
    end)
  end

  return root
end
