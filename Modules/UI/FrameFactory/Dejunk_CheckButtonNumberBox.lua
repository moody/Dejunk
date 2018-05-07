-- Dejunk_CheckButtonNumberBox: contains FrameFactory functions to create a CheckButton & EditBox combo frame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local abs, tonumber = abs, tonumber

-- Dejunk
local FrameFactory = DJ.FrameFactory

local DejunkDB = DJ.DejunkDB
local Tools = DJ.Tools
local FrameCreator = DJ.FrameCreator

-- ============================================================================
--                             Creation Function
-- ============================================================================

function FrameFactory:CreateCheckButtonNumberBox(parent, size, text, textColor, tooltip, svKey, maxLetters)
  assert(svKey and type(DejunkDB.SV[svKey]) == "table")

  local cbnBox = FrameCreator:CreateFrame(parent)
  cbnBox.FF_ObjectType = "CheckButtonNumberBox"

  local checkButton = self:CreateCheckButton(cbnBox, size, text, textColor, tooltip)
  cbnBox.CheckButton = checkButton

  local editBoxFrame = self:CreateEditBoxFrame(cbnBox, checkButton.Text:GetFontObject(), maxLetters, true)
  cbnBox.EditBoxFrame = editBoxFrame

  -- Initialize points
  checkButton:SetPoint("TOPLEFT")
  editBoxFrame:SetPoint("TOPLEFT", checkButton, "BOTTOMLEFT", Tools:Padding(), 0)

  -- CheckButton
  checkButton:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    DejunkDB:Set(svKey..".Enabled", checked)
    editBoxFrame.EditBox:SetEnabled(checked)
  end)

  -- EditBox
  editBoxFrame.EditBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText() end)
  editBoxFrame.EditBox:SetScript("OnEditFocusLost", function(self)
    self:HighlightText(0, 0)
    self:SetText(DejunkDB.SV[svKey].Value)
  end)
  editBoxFrame.EditBox:SetScript("OnTextChanged", function(self)
    local value = self:GetNumber()
    DejunkDB:Set(svKey..".Value", floor(abs(value)))
  end)

  -- Gets the minimum width of the frame.
  function cbnBox:GetMinWidth()
    return max(checkButton:GetMinWidth(),
      editBoxFrame:GetWidth() + Tools:Padding())
  end

  -- Gets the minimum height of the frame.
  function cbnBox:GetMinHeight()
    return (checkButton:GetMinHeight() + editBoxFrame:GetHeight())
  end

  -- Resizes the frame.
  function cbnBox:Resize()
    editBoxFrame:Resize()

    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  function cbnBox:Refresh()
    checkButton:Refresh()
    editBoxFrame:Refresh()

    local enabled = DejunkDB.SV[svKey].Enabled
    checkButton:SetChecked(enabled)
    editBoxFrame.EditBox:SetEnabled(enabled)
    editBoxFrame.EditBox:SetText(DejunkDB.SV[svKey].Value)
  end

  cbnBox:Refresh()

  return cbnBox
end

function FrameFactory:EnableCheckButtonNumberBox(cbnBox)
  cbnBox.CheckButton:SetEnabled(true)
  cbnBox.EditBoxFrame.EditBox:SetEnabled(true)
end

function FrameFactory:DisableCheckButtonNumberBox(cbnBox)
  cbnBox.CheckButton:SetEnabled(false)
  cbnBox.EditBoxFrame.EditBox:SetEnabled(false)
end
