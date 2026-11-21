local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TabOptions
--- @field labelText string
--- @field onClick fun(self: TabComponent)

-- =============================================================================
-- ComponentFactory - Tab
-- =============================================================================

--- Creates a tab button. Selected, it has a blue underline and white label; otherwise grey, and white on hover.
--- @param options TabOptions
--- @return TabComponent root
function ComponentFactory:Tab(options)
  local root
  local isSelected = false

  --- Applies selected, hovered, or normal colors.
  --- @param frame TabWidget
  local function refreshColors(frame)
    if isSelected then
      frame:SetBackdropColor(Colors.Blue:GetRGBA(0.1))
      frame.label:SetTextColor(Colors.White:GetRGBA())
      frame.underline:SetHeight(2)
      frame.underline:SetColorTexture(Colors.Blue:GetRGBA())
    else
      local isHovered = frame:GetEventValue("HOVERED")
      frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.1 or 0))
      frame.label:SetTextColor((isHovered and Colors.White or Colors.Grey):GetRGBA())
      frame.underline:SetHeight(1)
      frame.underline:SetColorTexture(Colors.White:GetRGBA(0.15))
    end
  end

  --- @class TabComponent : WaffleFlexComponent<TabWidget>
  root = Addon.Waffle:Flex({
    height = "AUTO",

    frameFactory = function(parent)
      --- @class TabWidget : FrameWidget, Button
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", B.FontObjects.Normal:GetName())
      frame.label:SetPoint("LEFT", Widgets:Padding(), 0)
      frame.label:SetPoint("RIGHT", -Widgets:Padding(), 0)
      frame.label:SetJustifyH("CENTER")
      frame.label:SetWordWrap(false)
      frame.label:SetText(options.labelText)

      frame.underline = frame:CreateTexture("$parent_Underline", "OVERLAY")
      frame.underline:SetPoint("BOTTOMLEFT")
      frame.underline:SetPoint("BOTTOMRIGHT")

      frame:SetScript("OnClick", function() options.onClick(root) end)

      frame:OnEvent("HOVERED", function() refreshColors(frame) end)

      return frame
    end,

    --- @param frame TabWidget
    --- @param width number
    --- @return number, number
    onMeasure = function(frame, width)
      return width, frame.label:GetStringHeight() + Widgets:Padding(2)
    end
  })

  --- Sets whether the tab is selected.
  --- @param selected boolean
  function root:SetSelected(selected)
    isSelected = selected
    self:WhenFrameReady(refreshColors)
  end

  return root
end
