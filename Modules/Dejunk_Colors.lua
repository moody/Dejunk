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

-- Dejunk_Colors: provides Dejunk modules easy access to various colors.

local AddonName, DJ = ...

-- Dejunk
local Colors = DJ.Colors

local DejunkDB = DJ.DejunkDB

-- Variables
Colors.ColorSchemes = {}
Colors.CurrentScheme = nil

--[[
//*******************************************************************
//                         General Functions
//*******************************************************************
--]]

-- Initializes the Colors table.
function Colors:Initialize()
  if self.Initialized then return end

  assert(DejunkDB.Initialized == true, "DejunkDB has not been initialized")

  local colorScheme = DejunkGlobal.ColorScheme
  if (colorScheme == nil) or (self.ColorSchemes[colorScheme] == nil) then
    colorScheme = "Default"
  end

  self:SetColorScheme(colorScheme)

  self.Initialized = true
end

-- Sets the current color scheme.
-- @param colorScheme - a colorScheme defined in Colors.ColorSchemes
function Colors:SetColorScheme(colorScheme)
  assert(type(colorScheme) == "string", "colorScheme must exist and be a string")
  assert(self.ColorSchemes[colorScheme] ~= nil,
    format("a color scheme with the name \"%s\" does not exist", colorScheme))

  DejunkGlobal.ColorScheme = colorScheme
  self.CurrentScheme = self.ColorSchemes[colorScheme]()
end

-- Returns a color table specified by name.
-- @param color - the key of the color to return
-- @param alpha - the alpha of the color [optional]
-- @return - a color table: {r, g, b, a}
function Colors:GetColor(color, alpha)
  assert(type(color) == "string", "color must exist and be a string")
  assert(self[color] ~= nil, format("\"%s\" is not a valid color", color))

  local color = (self.ConstantColors[color] or
                 self.CurrentScheme[color] or
                 self.DefaultColors[color])

  if alpha then color[4] = alpha end

  return color
end

-- Returns a color table specified by item quality.
-- @param quality - a value between LE_ITEM_QUALITY_POOR and LE_ITEM_QUALITY_LEGENDARY
function Colors:GetColorByQuality(quality)
  local check = (quality >= LE_ITEM_QUALITY_POOR) and (quality <= LE_ITEM_QUALITY_LEGENDARY)
  assert(check, "invalid item quality")

  if (quality == LE_ITEM_QUALITY_POOR) then
    return self:GetColor(self.Poor)
  elseif (quality == LE_ITEM_QUALITY_COMMON) then
    return self:GetColor(self.Common)
  elseif (quality == LE_ITEM_QUALITY_UNCOMMON) then
    return self:GetColor(self.Uncommon)
  elseif (quality == LE_ITEM_QUALITY_RARE) then
    return self:GetColor(self.Rare)
  elseif (quality == LE_ITEM_QUALITY_EPIC) then
    return self:GetColor(self.Epic)
  elseif (quality == LE_ITEM_QUALITY_LEGENDARY) then
    return self:GetColor(self.Legendary)
  end
end

--[[
//*******************************************************************
//                           Color Schemes
//*******************************************************************
--]]

-- Returns the default color scheme.
function Colors.ColorSchemes:Default()
  return Colors.DefaultColors
end

-- Returns the "Redscale" color scheme.
function Colors.ColorSchemes:Redscale()
  return
  {
    BaseFrame = {0.05, 0, 0, 0.95},

    BaseFrameTitle = {0.5, 0.247, 0.247, 1},
    BaseFrameTitleShadow = {0.2, 0.05, 0.05, 1},

    Button   = {0.15, 0.05, 0.05, 1},
    ButtonHi = {0.3, 0.15, 0.15, 1},
    ButtonText = {1, 0.5, 0.5, 1},
    ButtonTextHi = {1, 1, 1, 1},

    Separator = {0.3, 0.15, 0.15, 1},

    LabelText = {0.6, 0.35, 0.35, 1},

    Inclusions = {0.8, 0.247, 0.247, 1},
    InclusionsHi = {0.9, 0.4, 0.4, 1},

    Exclusions = {0.247, 0.8, 0.247, 1},
    ExclusionsHi = {0.4, 0.9, 0.4, 1},

    Area = {0.2, 0.1, 0.1, 0.5},

    ScrollFrame = {0.2, 0.1, 0.1, 0.5},
    Slider = {0.2, 0.1, 0.1, 0.5},
    SliderThumb = {0.2, 0.1, 0.1, 1},
    SliderThumbHi = {0.3, 0.15, 0.15, 1},
    ListButton = {0.2, 0.1, 0.1, 1},
    ListButtonHi = {0.3, 0.15, 0.15, 1},
  }
end

--[[
//*******************************************************************
//                             Color Tables
//*******************************************************************
--]]

-- Constant colors, such as black
Colors.ConstantColors =
{
  None = {0, 0, 0, 0},
  Red = {1, 0, 0, 1},
  Green = {0, 1, 0, 1},
  Blue = {0, 0, 1, 1},
  White = {1, 1, 1, 1},
  Black = {0, 0, 0, 1},
  Grey = {0.5, 0.5, 0.5, 1},
  Magenta = {1, 0, 1, 1},
}

-- Default Dejunk colors
Colors.DefaultColors =
{
  BaseFrame = {0, 0, 0.05, 0.95},

  BaseFrameTitle = {0.247, 0.247, 0.5, 1},
  BaseFrameTitleShadow = {0.05, 0.05, 0.2, 1},

  Button   = {0.05, 0.05, 0.15, 1},
  ButtonHi = {0.15, 0.15, 0.3, 1},
  ButtonDisabled = {0.04, 0.04, 0.10, 1},
  ButtonText = {0.5, 0.5, 1, 1},
  ButtonTextHi = {1, 1, 1, 1},
  ButtonTextDisabled = {0.7, 0.7, 0.8, 1},

  Separator = {0.15, 0.15, 0.3, 1},

  LabelText = {0.35, 0.35, 0.6, 1},

  Poor = {0.62, 0.62, 0.62, 1},
  Common = {1, 1, 1, 1},
  Uncommon = {0.12, 1, 0, 1},
  Rare = {0, 0.44, 0.87, 1},
  Epic = {0.64, 0.21, 0.93, 1},
  Legendary = {1, 0.5, 0, 1},

  Inclusions = {0.8, 0.247, 0.247, 1},
  InclusionsHi = {0.9, 0.4, 0.4, 1},

  Exclusions = {0.247, 0.8, 0.247, 1},
  ExclusionsHi = {0.4, 0.9, 0.4, 1},

  Area = {0.1, 0.1, 0.2, 0.5},

  ScrollFrame = {0.1, 0.1, 0.2, 0.5},
  Slider = {0.1, 0.1, 0.2, 0.5},
  SliderThumb = {0.1, 0.1, 0.2, 1},
  SliderThumbHi = {0.15, 0.15, 0.3, 1},
  ListButton = {0.1, 0.1, 0.2, 1},
  ListButtonHi = {0.15, 0.15, 0.3, 1},
}

-- Here we add the ConstantColors' and DefaultColors' keys to Colors.
-- This allows us to call GetColor like so: Colors:GetColor(Colors.Key)
-- Where "Key" is a key (color name) in ConstantColors or DefaultColors
for k in pairs(Colors.ConstantColors) do Colors[k] = k end
for k in pairs(Colors.DefaultColors) do Colors[k] = k end
