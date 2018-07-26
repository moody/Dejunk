-- Button: contains functions to create a DFL button.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local GetMouseFocus = GetMouseFocus
local ceil, pairs, unpack = ceil, pairs, unpack

-- Button
local Button = DFL.Button
Button.Scripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL button.
-- @param parent - the parent frame
-- @param text - the string to set the button's text [optional]
-- @param font - the font of the button's text [optional]
function Button:Create(parent, text, font)
  local button = DFL.Creator:CreateButton(parent)
  button._texture = DFL.Creator:CreateTexture(button)
  button._label = DFL.FontString:Create(button, text, font)
  button:SetFontString(button._label)

  DFL:AddDefaults(button)
  DFL:AddMixins(button, self.Functions)
  DFL:AddScripts(button, self.Scripts)

  button:SetColors()
  button:Refresh()

  return button
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = Button.Functions

  -- Sets the text for the button.
  function Functions:SetText(text)
    self._label:SetText(text)
    DFL:ResizeParent(self)
  end
    
  function Functions:SetColors(color, colorHi, textColor, textColorHi, borderColor)
    self._color = color or self._color or DFL.Colors.Button
    self._colorHi = colorHi or self._colorHi or DFL.Colors.ButtonHi
    self._textColor = textColor or self._textColor or DFL.Colors.Text
    self._textColorHi = textColorHi or self._textColorHi or DFL.Colors.White
    self._borderColor = borderColor or self._borderColor
  end

  function Functions:OnSetEnabled(enabled)
    DFL:SetEnabledAlpha(self, enabled)
  end

  function Functions:Refresh()
    if (self == GetMouseFocus()) then
      self:GetScript("OnEnter")(self)
    else
      self:GetScript("OnLeave")(self)
    end

    if self._borderColor then DFL:AddBorder(self, unpack(self._borderColor)) end
  end

  function Functions:Resize()
    local width = ceil(self._label:GetStringWidth()) + DFL:Padding()
    local height = ceil(self._label:GetStringHeight()) + DFL:Padding()
    if (width < height) then width = height end
    self:SetSize(width, height)
  end
end
-- ============================================================================
-- Scripts
-- ============================================================================
do
  local Scripts = Button.Scripts
  
  function Scripts:OnClick(button, down)
    if self.OnClick then self:OnClick(button, down) end
  end

  function Scripts:OnEnter()
    self._texture:SetColorTexture(unpack(self._colorHi))
    self._label:SetTextColor(unpack(self._textColorHi))
  end

  function Scripts:OnLeave()
    self._texture:SetColorTexture(unpack(self._color))
    self._label:SetTextColor(unpack(self._textColor))
  end
end
