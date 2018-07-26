-- TextArea: contains functions to create a DFL text area.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

local Points = DFL.Points

-- TextArea
local TextArea = DFL.TextArea
TextArea.Scripts = {}
TextArea.EditBoxScripts = {}
TextArea.SliderScripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL text area.
-- @param parent - the parent frame
-- @param sliderSpacing - spacing between the frame and slider
-- @param padding - padding between the frame edges and text
function TextArea:Create(parent, sliderSpacing, padding)
  local frame = DFL.Creator:CreateFrame(parent)
  frame._sliderSpacing = tonumber(sliderSpacing) or DFL:Padding(0.25)
  padding = tonumber(padding) or DFL:Padding(0.5)

  -- Texture, used to position the scroll frame to allow for padding without
  -- using SetTextInsets() on the edit box. Doing it this way because it
  -- doesn't cause text to spill out over the bottom edge of the texture.
  local texture = DFL.Texture:Create(frame)
  frame._texture = texture

  -- Scroll frame
  local scrollFrame = DFL.Creator:CreateScrollFrame(frame)
  scrollFrame:SetPoint(Points.TOPLEFT, texture, padding, -padding)
  scrollFrame:SetPoint(Points.BOTTOMRIGHT, texture, -padding, padding)
  frame._scrollFrame = scrollFrame

  -- Edit box (scroll child)
  local editBox = DFL.Creator:CreateEditBox(scrollFrame)
  editBox:SetMultiLine(true)
  editBox.cursorOffset = 0 -- For ScrollingEdit_* functions
  editBox.cursorHeight = 0 -- For ScrollingEdit_* functions
  editBox._frame = frame
  frame._editBox = editBox
  
  scrollFrame:SetScrollChild(editBox)

  -- Slider
  local slider = DFL.Slider:Create(frame)
  slider.SetEnabled = nop
  slider._scrollFrame = scrollFrame
  frame._slider = slider

  DFL:AddDefaults(frame)
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(frame, self.Scripts)
  DFL:AddScripts(editBox, self.EditBoxScripts)
  DFL:AddScripts(slider, self.SliderScripts)

  frame:SetMinWidth(100)
  frame:SetMinHeight(100)

  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = TextArea.Functions

  -- Updates the visibility of the slider.
  function Functions:UpdateSlider()
    local scrollFrame = self._scrollFrame
    local editBox = self._editBox
    local slider = self._slider
    local spacing = self._sliderSpacing
    local texture = self._texture

    -- Update slider values, reposition texture
    local maxVal = max(editBox:GetHeight() - scrollFrame:GetHeight(), 0)
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

    editBox:SetWidth(scrollFrame:GetWidth())
  end

  -- Sets the colors of the text area.
  function Functions:SetColors(textColor, textureColor, sliderColors)
    self._textColor = textColor or DFL.Colors.Text
    self._texture:SetColors(textureColor or DFL.Colors.Area)
    if sliderColors then self._slider:SetColors(unpack(sliderColors)) end
  end

  -- Enables or disables the text area.
  function Functions:OnSetEnabled(enabled)
    self._editBox:SetEnabled(enabled)
    DFL:SetEnabledAlpha(self._editBox, enabled)
  end

  -- Refreshes the text area.
  function Functions:Refresh()
    self._editBox:SetTextColor(unpack(self._textColor))
    self._texture:Refresh()
    self._slider:Refresh()
  end

  -- Resizes the text area.
  function Functions:Resize()
    local scrollFrame = self._scrollFrame
    local editBox = self._editBox
    local slider = self._slider

    slider:Resize()

    local minWidth = self:GetMinWidth() + (self._sliderSpacing + slider:GetWidth())
    local minHeight = self:GetMinHeight()

    self:SetWidth(minWidth)
    self:SetHeight(minHeight)
  end

  Functions.OnSetHeight = Functions.UpdateSlider
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = TextArea.Scripts

  -- Update the slider when the mouse wheel is scrolled.
  function Scripts:OnMouseWheel(delta)
    local slider = self._slider
    -- scroll by 12.5% on each wheel (delta will be 1 or -1)
    local percent = (select(2, slider:GetMinMaxValues()) * 0.125 * delta)
    slider:SetValue(slider:GetValue() - percent)
  end

  -- When frame is clicked, set focus on the edit box and reposition the cursor
  -- to the end of it.
  function Scripts:OnMouseUp()
    self._editBox:SetFocus()
    self._editBox:HighlightText(0, 0)
    self._editBox:SetCursorPosition(self._editBox:GetNumLetters())
  end
end

-- ============================================================================
-- EditBoxScripts
-- ============================================================================

do
  local Scripts = TextArea.EditBoxScripts

  function Scripts:OnUpdate(elapsed)
    self._frame:UpdateSlider()
    ScrollingEdit_OnUpdate(self, elapsed)
    local scroll = self:GetParent():GetVerticalScroll()
    self._frame._slider:SetValue(scroll)
  end

  Scripts.OnCursorChanged = ScrollingEdit_OnCursorChanged
end

-- ============================================================================
-- SliderScripts
-- ============================================================================

do
  local SliderScripts = TextArea.SliderScripts

  -- Update the scroll frame when the slider's value changes.
  function SliderScripts:OnValueChanged(value)
    self._scrollFrame:SetVerticalScroll(value)
  end
end
