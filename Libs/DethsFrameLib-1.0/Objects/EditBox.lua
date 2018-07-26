-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local unpack = unpack

-- EditBox
local EditBox = DFL.EditBox
EditBox.EditBoxScripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL edit box.
-- @param parent - the parent frame
-- @param maxLetters - the maximum amount of characters [optional]
-- @param numeric - whether or not the edit box only accepts numeric input [optional]
-- @param font - the font style for the edit box to inherit [optional]
function EditBox:Create(parent, maxLetters, numeric, font)
  local frame = DFL.Creator:CreateFrame(parent)
  frame._texture = DFL.Texture:Create(frame)

  local editBox = DFL.Creator:CreateEditBox(frame, maxLetters, numeric, font)
  editBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
  editBox:SetPoint("TOPLEFT", DFL:Padding(0.5), -DFL:Padding(0.25))
  editBox:SetPoint("BOTTOMRIGHT", -DFL:Padding(0.5), DFL:Padding(0.25))
  editBox.SetMultiLine = nop
  frame._editBox = editBox

  DFL:AddDefaults(frame)
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(editBox, self.EditBoxScripts)

  frame:SetMinWidth(50)
  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = EditBox.Functions

  function Functions:SetPrevTabTarget(object)
    assert(type(object.SetFocus) == "function", "object does not support SetFocus()")
    self._editBox._prevTabTarget = object
  end

  function Functions:SetNextTabTarget(object)
    assert(type(object.SetFocus) == "function", "object does not support SetFocus()")
    self._editBox._nextTabTarget = object
  end
  
  function Functions:SetColors(textColor, textureColor, borderColor)
    self._textColor = textColor or self._textColor or DFL.Colors.Text
    self._texture:SetColors(textureColor or DFL.Colors.Frame)
    self._borderColor = borderColor or self._borderColor or DFL.Colors.Area
  end

  function Functions:OnSetEnabled(enabled)
    DFL:SetEnabledAlpha(self, enabled)
    self._editBox:SetEnabled(enabled)
  end

  function Functions:Refresh()
    self._editBox:SetTextColor(unpack(self._textColor))
    self._texture:Refresh()
    DFL:AddBorder(self, unpack(self._borderColor))
    
    if self._editBox:HasFocus() then self._editBox:ClearFocus() end
    if self.GetUserValue then self._editBox:SetText(self:GetUserValue()) end
  end

  function Functions:Resize()
    local _, height = self._editBox:GetFont()
    self:SetWidth(self:GetMinWidth())
    self:SetHeight(height + DFL:Padding())
  end
end
-- ============================================================================
-- EditBoxScripts
-- ============================================================================
do
  local EditBoxScripts = EditBox.EditBoxScripts
  local IsShiftKeyDown = IsShiftKeyDown

  function EditBoxScripts:OnTextChanged()
    local value = self:IsNumeric() and self:GetNumber() or self:GetText()
    local parent = self:GetParent()
    if parent.SetUserValue then parent:SetUserValue(value) end
  end

  function EditBoxScripts:OnEditFocusLost()
    self:HighlightText(0, 0)
    local parent = self:GetParent()
    if parent.GetUserValue then self:SetText(parent:GetUserValue()) end
  end

  function EditBoxScripts:OnTabPressed()
    if (IsShiftKeyDown()) then
      if self._prevTabTarget then self._prevTabTarget:SetFocus() end
    else
      if self._nextTabTarget then self._nextTabTarget:SetFocus() end
    end
  end
end
