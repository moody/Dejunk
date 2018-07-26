-- CheckButton: contains functions to create a DFL check button.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local assert, ceil, pairs, type, unpack =
      assert, ceil, pairs, type, unpack

-- CheckButton
local CheckButton = DFL.CheckButton
CheckButton.Scripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL check button.
-- @param parent - the parent frame
-- @param text - the string to set the check button's text [optional]
-- @param tooltip - the body text of the tooltip shown when highlighted [optional]
-- @param font - the font of the check button's text [optional]
function CheckButton:Create(parent, text, tooltip, font)
  local frame = DFL.Creator:CreateFrame(parent)
  frame._tooltip = tooltip

  local checkButton = DFL.Creator:CreateCheckButton(frame)
  checkButton:SetPoint("TOPLEFT")
  frame._checkButton = checkButton
  
  frame._texture = DFL.Creator:CreateTexture(checkButton)
  frame._label = DFL.FontString:Create(checkButton, text, font)
  frame._label:SetPoint("LEFT", checkButton, "RIGHT", DFL:Padding(0.5), 0)

  DFL:AddDefaults(frame)
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(checkButton, self.Scripts)
  
  frame:SetColors()
  frame:Refresh()

  return frame
end


-- ============================================================================
-- Functions
-- ============================================================================
do
  local Functions = CheckButton.Functions

  function Functions:GetChecked()
    return self._checkButton:GetChecked()
  end

  function Functions:SetChecked(checked)
    self._checkButton:SetChecked(checked)
    if self.SetUserValue then self:SetUserValue(checked) end
  end

  function Functions:GetText()
    return self._label:GetText()
  end

  function Functions:SetText(text)
    self._label:SetText(text)
    DFL:ResizeParent(self)
  end

  function Functions:GetTooltip()
    return self._tooltip
  end

  function Functions:SetTooltip(tooltip)
    self._tooltip = tooltip
  end

  function Functions:SetColors(textColor, textureColor, borderColor)
    self._label:SetColors(textColor)
    self._textureColor = textureColor or self._textureColor or DFL.Colors.Area
    self._borderColor = borderColor or self._borderColor or DFL.Colors.Black
  end

  function Functions:OnSetEnabled(enabled)
    DFL:SetEnabledAlpha(self, enabled)
    self._checkButton:SetEnabled(enabled)
  end

  function Functions:Refresh()
    self._label:Refresh()
    self._texture:SetColorTexture(unpack(self._textureColor))
    DFL:AddBorder(self._checkButton, unpack(self._borderColor))
    if self.GetUserValue then self._checkButton:SetChecked(self:GetUserValue()) end
  end

  function Functions:Resize()
    local cbSize = ceil(self._label:GetStringHeight()) + DFL:Padding(0.3)
    local width = ceil(cbSize + self._label:GetStringWidth() + DFL:Padding(0.5))

    self._checkButton:SetWidth(cbSize)
    self._checkButton:SetHeight(cbSize)

    self:SetSize(width, cbSize)
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = CheckButton.Scripts
  
  function Scripts:OnClick()
    local parent = self:GetParent()
    if parent.SetUserValue then parent:SetUserValue(self:GetChecked()) end
  end

  function Scripts:OnEnter()
    local parent = self:GetParent()
    if parent._tooltip then
      DFL:ShowTooltip(parent, DFL.Anchors.TOP, parent._label:GetText(), parent._tooltip)
    end
  end

  Scripts.OnLeave = DFL.HideTooltip
end
