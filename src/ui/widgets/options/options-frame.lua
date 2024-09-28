local Addon = select(2, ...) ---@type Addon

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionsFrameWidgetOptions : ScrollableTitleFrameWidgetOptions

-- =============================================================================
-- Widgets - Options Frame
-- =============================================================================

--- Creates a ScrollableTitleFrame with a scroll child for adding children.
--- @param options OptionsFrameWidgetOptions
--- @return OptionsFrameWidget frame
function Widgets:OptionsFrame(options)
  local CHILD_SPACING = Widgets:Padding()

  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("OptionsFrame"))
  options.titleJustify = "CENTER"

  --- @class OptionsFrameWidget : ScrollableTitleFrameWidget
  local frame = self:ScrollableTitleFrame(options)
  frame.titleButton:EnableMouse(false)
  frame.children = {}

  -- Scroll child.
  frame.scrollChild = self:Frame({ name = "$parent_ScrollChild", parent = frame.scrollFrame })
  frame.scrollChild:SetBackdrop(nil)
  frame.scrollFrame:SetScrollChild(frame.scrollChild)

  --- Adds a child frame.
  --- @param child Region
  function frame:AddChild(child)
    child:SetParent(self.scrollChild)
    self.children[#self.children + 1] = child
  end

  -- Hook `OnUpdate` script.
  frame:HookScript("OnUpdate", function(_, elapsed)
    frame.refreshTimer = (frame.refreshTimer or 0.2) + elapsed
    if frame.refreshTimer < 0.2 then return end
    frame.refreshTimer = 0

    -- Calculate total height of children.
    local childrenHeight = 0
    for _, child in ipairs(frame.children) do
      childrenHeight = childrenHeight + child:GetHeight()
    end

    -- Calculate total spacing between children.
    local childrenSpacing = (#frame.children - 1) * CHILD_SPACING

    -- Update scroll child height.
    frame.scrollChild:SetHeight(childrenHeight + childrenSpacing)

    -- Update child points.
    for i, child in ipairs(frame.children) do
      child:ClearAllPoints()
      if i == 1 then
        child:SetPoint("TOPLEFT", frame.scrollChild)
        child:SetPoint("TOPRIGHT", frame.scrollChild)
      else
        child:SetPoint("TOPLEFT", frame.children[i - 1], "BOTTOMLEFT", 0, -CHILD_SPACING)
        child:SetPoint("TOPRIGHT", frame.children[i - 1], "BOTTOMRIGHT", 0, -CHILD_SPACING)
      end
    end
  end)

  return frame
end
