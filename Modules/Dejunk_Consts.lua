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

-- Dejunk_Consts: provides Dejunk modules easy access to constant values.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Consts = DJ.Consts

--[[
//*******************************************************************
//  					    			   General Constants
//*******************************************************************
--]]

Consts.SAFE_MODE_MAX = 12

--[[
//*******************************************************************
//  					    			      UI Constants
//*******************************************************************
--]]

Consts.MIN_WIDTH = 685
Consts.MIN_HEIGHT = 390

Consts.PADDING = 10

-- List
Consts.LIST_FRAME_MIN_WIDTH = 300
Consts.LIST_BUTTON_HEIGHT = 32
Consts.LIST_BUTTON_ICON_SIZE = 25

-- Slider
Consts.SLIDER_DEFAULT_WIDTH = 16
Consts.THUMB_DEFAULT_HEIGHT = 32

-- TextField
Consts.TEXT_FIELD_MIN_WIDTH = 150
