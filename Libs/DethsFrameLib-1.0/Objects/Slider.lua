-- Slider: contains functions to create a DFL slider.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local Clamp = Clamp
local assert, format, pairs, tonumber, type, unpack =
      assert, format, pairs, tonumber, type, unpack

-- Slider
local Slider = DFL.Slider
Slider.Scripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL slider.
-- @param parent - the parent frame
function Slider:Create(parent)
  local slider = DFL.Creator:CreateSlider(parent)
  slider._texture = DFL.Creator:CreateTexture(slider)
  slider._thumb = DFL.Creator:CreateTexture(slider)
  slider:SetThumbTexture(slider._thumb)
  
  slider._tooltip_anchor = DFL.Anchors.TOP

  DFL:AddDefaults(slider)
  DFL:AddMixins(slider, self.Functions)
  DFL:AddScripts(slider, self.Scripts)

  slider:SetSize(10, 10)
  slider:SetColors()
  slider:Refresh()

  return slider
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = Slider.Functions

  -- If true, a tooltip with the current value is displayed upon interaction.
  -- @param b - boolean
  function Functions:SetShowTooltip(b)
    self._show_tooltip = not not b
  end

  -- Sets the anchor point of the tooltip.
  function Functions:SetTooltipAnchor(anchor)
    self._tooltip_anchor = anchor or DFL.Anchors.TOP
  end

  -- If true, the slider's value will be clamped to a maximum number of decimals.
  -- Example: if set to 2, 3.14159 becomes 3.14
  function Functions:SetMaxDecimals(maxDecimals)
    assert(type(maxDecimals) == "number", "maxDecimals must be a number")
    self._max_decimals = maxDecimals
  end

  function Functions:SetColors(color, thumbColor, thumbColorHi)
    self._color = color or self._color or DFL.Colors.Area
    self._thumbColor = thumbColor or self._thumbColor or DFL.Colors.Thumb
    self._thumbColorHi = thumbColorHi or self._thumbColorHi or DFL.Colors.ButtonHi
  end

  function Functions:Refresh()
    self._texture:SetColorTexture(unpack(self._color))
    self._thumb:SetColorTexture(unpack(self._thumbColor))
    if self.GetUserValue then self:SetValue(self:GetUserValue()) end
  end

  function Functions:Resize()
    local width, height = 0, 0
    if (self:GetOrientation() == DFL.Orientations.VERTICAL) then
      width = self:GetWidth()
      height = width * 2
    else
      height = self:GetHeight()
      width = height * 2
    end
    self._thumb:SetSize(width, height)
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = Slider.Scripts
    
  local function showTooltip(self, value)
    DFL:ShowTooltip(self._thumb, self._tooltip_anchor, value)
  end

  function Scripts:OnValueChanged(value)
    local minVal, maxVal = self:GetMinMaxValues()
    value = Clamp(value, minVal, maxVal)

    -- Round if necessary
    if self._max_decimals then
      value = tonumber(format("%."..self._max_decimals.."f", value))
    end
    
    -- Show tooltip if necessary
    if self._show_tooltip and self._mouse_down then showTooltip(self, value) end

    -- Only call SetUserValue handler if value has changed
    if self.SetUserValue and (self._last_value ~= value) then
      self:SetUserValue(value)
    end

    self._last_value = value
  end

  function Scripts:OnMouseDown()
    self._thumb:SetColorTexture(unpack(self._thumbColorHi))
    self._mouse_down = true
    if self._show_tooltip then showTooltip(self, self:GetValue()) end
  end

  function Scripts:OnMouseUp()
    self._thumb:SetColorTexture(unpack(self._thumbColor))
    self._mouse_down = false
    if self._show_tooltip then DFL:HideTooltip() end
  end
end
