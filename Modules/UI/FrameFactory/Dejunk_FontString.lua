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

-- Dejunk_FontString: contains FrameFactory functions to create and release a font string tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local FrameCreator = DJ.FrameCreator

--[[
//*******************************************************************
//  					    			 Font String Functions
//*******************************************************************
--]]

-- Returns a font string tailored to Dejunk.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param font - the font style to inherit [optional]
-- @param color - the color of the font string: {r, g, b[, a]} [optional]
-- @param shadowOffset - the offset of the font string's shadow [optional]
-- @param shadowColor - the color of the font string's shadow [optional]
-- @return - a Dejunk font string
function FrameFactory:CreateFontString(parent, layer, font, color, shadowOffset, shadowColor)
  local fontString = FrameCreator:CreateFontString(parent, layer, font, nil, shadowOffset, nil)
  fontString.FF_ObjectType = "FontString"

  -- Refreshes the font string.
  function fontString:Refresh()
    self:SetTextColor(unpack(Colors:GetColor(self.Color)))
    self:SetShadowColor(unpack(Colors:GetColor(self.ShadowColor)))
  end

  -- Sets the colors for the font string.
  function fontString:SetColors(color, shadowColor)
    self.Color = (color or self.Color or Colors.White)
    self.ShadowColor = (shadowColor or self.ShadowColor or Colors.Black)

    self:Refresh()
  end

  fontString:SetColors(color, shadowColor)

  return fontString
end
