-- Dejunk_TextField: contains FrameFactory functions to create a labeled edit box.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Tools = DJ.Tools
local FrameCreator = DJ.FrameCreator

--[[
//*******************************************************************
//  					    			    TextField Functions
//*******************************************************************
--]]

-- Creates and returns a frame containing an edit box frame with an above label text,
-- and a below helper text.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @return - a Dejunk text field
function FrameFactory:CreateTextField(parent, font)
  local textField = FrameCreator:CreateFrame(parent)
  textField.FF_ObjectType = "TextField"

  textField.LabelFontString = self:CreateFontString(textField, nil, "GameFontNormal", Colors.LabelText)
  textField.LabelFontString:SetPoint("TOPLEFT")

  local editBoxFrame = self:CreateEditBoxFrame(textField, font)
  textField.EditBoxFrame = editBoxFrame
  editBoxFrame:SetPoint("LEFT")
  editBoxFrame:SetPoint("RIGHT")

  textField.HelperFontString = self:CreateFontString(textField, nil, "GameFontNormalSmall", Colors.LabelText)
  textField.HelperFontString:SetPoint("BOTTOMLEFT")

  function textField:SetLabelText(labelText)
    self.LabelFontString:SetText(labelText)
  end

  function textField:SetHelperText(helperText)
    self.HelperFontString:SetText(helperText)
  end

  function textField:Resize()
    editBoxFrame:Resize()

    local newWidth = max(self.LabelFontString:GetWidth(), self.HelperFontString:GetWidth())
    newWidth = max(newWidth, editBoxFrame:GetWidth())

    local newHeight= (self.LabelFontString:GetHeight() + Tools:Padding(0.5))
    newHeight = (newHeight + editBoxFrame:GetHeight() + Tools:Padding(0.5))
    newHeight = (newHeight + self.HelperFontString:GetHeight())

    self:SetWidth(newWidth)
    self:SetHeight(newHeight)
  end

  function textField:Refresh()
    self.LabelFontString:Refresh()
    editBoxFrame:Refresh()
    self.HelperFontString:Refresh()
  end

  textField:Refresh()

  return textField
end
