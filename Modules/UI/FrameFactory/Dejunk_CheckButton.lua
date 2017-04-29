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

-- Dejunk_CheckButton: contains FrameFactory functions to create and release a check button tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local DejunkDB = DJ.DejunkDB
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

-- Variables
local CheckButtonSizes =
{
  Small =
  {
    Size = 15,
    Font = "GameFontNormalSmall"
  },

  Normal =
  {
    Size = 20,
    Font = "GameFontNormal"
  },

  Huge =
  {
    Size = 30,
    Font = "GameFontNormalHuge"
  }
}

--[[
//*******************************************************************
//  					    			Check Button Functions
//*******************************************************************
--]]

-- Creates and returns a check button tailored to Dejunk.
-- @param parent - the parent frame
-- @param size - the size of the check button
-- @param font - the font of the check button's text
-- @param text - the string to set the check button's text
-- @param textColor - the color of the text [optional]
-- @param tooltip - the body text of the tooltip shown when highlighted [optional]
-- @param svKey - the key of the saved variable associated with the check button [optional]
-- @return - a Dejunk check button
function FrameFactory:CreateCheckButton(parent, size, text, textColor, tooltip, svKey)
  size = (CheckButtonSizes[size] or error("Unrecognized check button size"))

  local checkButton = FramePooler:CreateCheckButton(parent)
  checkButton:SetHeight(size.Size)
  checkButton:SetWidth(size.Size)

  checkButton.FF_ObjectType = "CheckButton"

  checkButton.Text = FramePooler:CreateFontString(checkButton, "OVERLAY", size.Font)
  checkButton.Text:SetPoint("LEFT", checkButton, "RIGHT", 0, 0)
  checkButton.Text:SetText(text)

  -- Returns the minimum width of the check button.
  function checkButton:GetMinWidth()
    return (self:GetWidth() + self.Text:GetStringWidth())
  end

  -- Returns the minimum height of the check button.
  function checkButton:GetMinHeight()
    return max(self:GetHeight(), self.Text:GetStringHeight())
  end

  -- Refreshes the check button.
  function checkButton:Refresh()
    -- Colors
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColor)))

    -- State
    if self.SVKey then self:SetChecked(DejunkDB.SV[self.SVKey]) end
  end

  -- Sets the colors for the check button.
  function checkButton:SetColors(textColor)
    self.TextColor = (textColor or self.TextColor or Colors.LabelText)
    self:Refresh()
  end

  -- Generic scripts
  if tooltip then
    checkButton:SetScript("OnEnter", function(self)
      Tools:ShowTooltip(self, "ANCHOR_RIGHT", self.Text:GetText(), tooltip) end)
    checkButton:SetScript("OnLeave", function() Tools:HideTooltip() end)
  end

  if svKey then
    checkButton.SVKey = svKey
    checkButton:SetChecked(DejunkDB.SV[svKey])

    checkButton:SetScript("OnClick", function(self)
      DejunkDB.SV[self.SVKey] = self:GetChecked()
    end)
  end

  checkButton:SetColors(textColor)

  return checkButton
end

-- Releases a check button created by FrameFactory.
-- @param checkButton - the check button to release
function FrameFactory:ReleaseCheckButton(checkButton)
  -- Objects
  FramePooler:ReleaseFontString(checkButton.Text)
  checkButton.Text = nil

  -- Variables
  checkButton.FF_ObjectType = nil
  checkButton.SVKey = nil
  checkButton.TextColor = nil

  -- Functions
  checkButton.GetMinWidth = nil
  checkButton.GetMinHeight = nil
  checkButton.Refresh = nil
  checkButton.SetColors = nil

  FramePooler:ReleaseCheckButton(checkButton)
end
