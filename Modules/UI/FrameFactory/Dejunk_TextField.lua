--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_TextField: contains FrameFactory functions to create and release a labeled edit box.

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
