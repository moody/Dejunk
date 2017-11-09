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

-- Dejunk_Button: contains FrameFactory functions to create and release a button tailored to Dejunk.

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
//  					    			    Button Functions
//*******************************************************************
--]]

-- Creates and returns a button tailored to Dejunk.
-- @param parent - the parent frame
-- @param font - the font of the button's text
-- @param text - the string to set the button's text
-- @param color - the color of the button [optional]
-- @param colorHi - the color of the button when highlighted [optional]
-- @param textColor - the color of the text [optional]
-- @param textColorHi - the color of the text when highlighted [optional]
-- @return - a Dejunk button
function FrameFactory:CreateButton(parent, font, text, color, colorHi, textColor, textColorHi)
  local button = FrameCreator:CreateButton(parent)
  button.FF_ObjectType = "Button"

  button.Texture = FrameCreator:CreateTexture(button)

  button.Text = FrameCreator:CreateFontString(button, "OVERLAY", font)
  button.Text:SetPoint("CENTER", 1, 0)
  button.Text:SetText(text)

  -- Resizes the button to its minimum required size.
  function button:Resize()
    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  -- Gets the minimum width required by the button to fit its contents.
  function button:GetMinWidth()
    return (self.Text:GetStringWidth() + Tools:Padding())
  end

  -- Gets the minimum height required by the button to fit its contents.
  function button:GetMinHeight()
    return (self.Text:GetStringHeight() + Tools:Padding())
  end

  -- Refreshes the button.
  function button:Refresh()
    if (self == GetMouseFocus()) then
      self:GetScript("OnEnter")(self)
    else
      self:GetScript("OnLeave")(self)
    end
  end

  -- Sets the colors for the button.
  function button:SetColors(color, colorHi, textColor, textColorHi)
    self.Color = (color or self.Color or Colors.Button)
    self.ColorHi = (colorHi or self.ColorHi or Colors.ButtonHi)
    self.TextColor = (textColor or self.TextColor or Colors.ButtonText)
    self.TextColorHi = (textColorHi or self.TextColorHi or Colors.ButtonTextHi)

    self:Refresh()
  end

  -- Generic scripts
  button:SetScript("OnEnter", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.ColorHi)))
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColorHi))) end)
	button:SetScript("OnLeave", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.Color)))
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColor))) end)

  button:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
  button:SetScript("OnDisable", function(self) self:SetAlpha(0.3) end)

  button:SetColors(color, colorHi, textColor, textColorHi)
  button:Resize()

  return button
end
