-- ScrollFrame: contains functions to create a DFL scroll frame.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

local Points = DFL.Points

-- ScrollFrame
local ScrollFrame = DFL.ScrollFrame
ScrollFrame.Scripts = {}
ScrollFrame.SliderScripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL scroll frame.
-- @param parent - the parent frame
-- @param sliderSpacing - spacing between the frame and slider
-- @param padding - scroll child padding
-- @param spacing - scroll child spacing
function ScrollFrame:Create(parent, sliderSpacing, padding, spacing)
  local frame = DFL.Creator:CreateFrame(parent)
  frame._sliderSpacing = tonumber(sliderSpacing) or DFL:Padding(0.25)
  padding = tonumber(padding) or DFL:Padding(0.5)
  frame._padding = padding

  -- Texture, used to position the scroll frame to allow for padding without
  -- using SetPadding() on the scroll child Frame. Doing it this way because it
  -- doesn't cause objects to spill out over the bottom edge of the texture.
  local texture = DFL.Texture:Create(frame)
  frame._texture = texture

  -- Scroll frame
  local scrollFrame = DFL.Creator:CreateScrollFrame(frame)
  scrollFrame:SetPoint(Points.TOPLEFT, texture, padding, -padding)
  scrollFrame:SetPoint(Points.BOTTOMRIGHT, texture, -padding, padding)
  frame._scrollFrame = scrollFrame

  -- Scroll child
  local scrollChild = DFL.Frame:Create(scrollFrame,
    DFL.Alignments.TOPLEFT, DFL.Directions.DOWN)
  scrollChild:SetSpacing(tonumber(spacing) or DFL:Padding(0.5))
  scrollFrame:SetScrollChild(scrollChild)
  frame._scrollChild = scrollChild

  -- Slider
  local slider = DFL.Slider:Create(frame)
  slider.SetEnabled = nop
  slider._scrollFrame = scrollFrame
  frame._slider = slider

  DFL:AddDefaults(frame)
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(frame, self.Scripts)
  DFL:AddScripts(slider, self.SliderScripts)

  frame:SetMinWidth(10)
  frame:SetMinHeight(10)

  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ScrollFrame.Functions

  -- Adds an object to the scroll frame.
  function Functions:Add(child)
    self._scrollChild:Add(child)
  end

  -- Removes an object from the scroll frame.
  function Functions:Remove(child)
    self._scrollChild:Remove(child)
  end

  -- Sets the colors of the scroll frame.
  function Functions:SetColors(color, sliderColors)
    self._texture:SetColors(color or DFL.Colors.Area)
    if sliderColors then self._slider:SetColors(unpack(sliderColors)) end
  end

  -- Enables or disables the scroll frame.
  function Functions:OnSetEnabled(enabled)
    self._scrollChild:SetEnabled(enabled)
  end

  -- Refreshes the scroll frame.
  function Functions:Refresh()
    self._texture:Refresh()
    self._scrollChild:Refresh()
    self._slider:Refresh()
  end

  -- Resizes the scroll frame.
  function Functions:Resize()
    local scrollFrame = self._scrollFrame
    local scrollChild = self._scrollChild
    local slider = self._slider

    scrollChild:Resize()
    slider:Resize()

    local scWidth = scrollChild:GetWidth() + (self._padding * 2)
    local sliderWidth = self._sliderSpacing + slider:GetWidth()
    
    self:SetWidth(max(self:GetMinWidth(), scWidth) + sliderWidth)
    self:SetHeight(self:GetMinHeight())
  end

  -- When the height is changed, update the visibility of the slider.
  function Functions:OnSetHeight()
    local scrollFrame = self._scrollFrame
    local scrollChild = self._scrollChild
    local slider = self._slider
    local spacing = self._sliderSpacing
    local texture = self._texture

    -- Update slider values, reposition texture
    local maxVal = max(scrollChild:GetHeight() - scrollFrame:GetHeight(), 0)
    texture:SetPoint(Points.TOPLEFT)
    if (maxVal > 0) then
      slider:SetMinMaxValues(0, maxVal)
      slider:Show()
      texture:SetPoint(Points.BOTTOMRIGHT, -(spacing + slider:GetWidth()), 0)
      slider:SetPoint(Points.TOPLEFT, texture, Points.TOPRIGHT, spacing, 0)
      slider:SetPoint(Points.BOTTOMLEFT, texture, Points.BOTTOMRIGHT, spacing, 0)
    else
      slider:SetMinMaxValues(0, 0)
      slider:Hide()
      texture:SetPoint(Points.BOTTOMRIGHT)
    end
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = ScrollFrame.Scripts

  -- Update the slider when the mouse wheel is scrolled.
  function Scripts:OnMouseWheel(delta)
    local slider = self._slider
    -- scroll by 12.5% on each wheel (delta will be 1 or -1)
    local percent = (select(2, slider:GetMinMaxValues()) * 0.125 * delta)
    slider:SetValue(slider:GetValue() - percent)
  end
end

-- ============================================================================
-- SliderScripts
-- ============================================================================

do
  local SliderScripts = ScrollFrame.SliderScripts

  -- Update the scroll frame when the slider's value changes.
  function SliderScripts:OnValueChanged(value)
    self._scrollFrame:SetVerticalScroll(value)
  end
end
