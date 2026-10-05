local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SelectableRowOptions
--- @field labelText string
--- @field onClick fun(self: SelectableRowComponent)

-- =============================================================================
-- ComponentFactory - SelectableRow
-- =============================================================================

--- Creates a button row that highlights while selected or hovered.
--- @param options SelectableRowOptions
--- @return SelectableRowComponent root
function ComponentFactory:SelectableRow(options)
  local root
  local isSelected = false

  --- Applies selected, hovered, or normal colors.
  --- @param frame SelectableRowWidget
  local function refreshColors(frame)
    if isSelected then
      frame:SetBackdropColor(Colors.Blue:GetRGBA(0.1))
      frame.label:SetTextColor(Colors.Blue:GetRGBA())
    elseif frame:GetEventValue("HOVERED") then
      frame:SetBackdropColor(Colors.White:GetRGBA(0.1))
      frame.label:SetTextColor(Colors.White:GetRGBA())
    else
      frame:SetBackdropColor(0, 0, 0, 0)
      frame.label:SetTextColor(Colors.Grey:GetRGBA())
    end
  end

  --- @class SelectableRowComponent : WaffleFlexComponent
  root = Addon.Waffle:Flex({
    height = "AUTO",

    frameFactory = function(parent)
      --- @class SelectableRowWidget : FrameWidget, Button
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
      frame.label:SetPoint("LEFT", Widgets:Padding(), 0)
      frame.label:SetPoint("RIGHT", -Widgets:Padding(), 0)
      frame.label:SetJustifyH("LEFT")
      frame.label:SetWordWrap(false)
      frame.label:SetText(options.labelText)

      frame:SetScript("OnClick", function() options.onClick(root) end)

      frame:OnEvent("HOVERED", function() refreshColors(frame) end)

      return frame
    end,

    --- @param frame SelectableRowWidget
    --- @param width number
    --- @return number, number
    onMeasure = function(frame, width)
      return width, frame.label:GetStringHeight() + Widgets:Padding(2)
    end
  })

  --- Sets whether the row is selected.
  --- @param selected boolean
  function root:SetSelected(selected)
    isSelected = selected
    self:WhenFrameReady(refreshColors)
  end

  return root
end
