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

-- Modules: initializes all of Dejunk's modules (tables) to circumvent load order issues.

local AddonName, DJ = ...

-- Initialize Dejunk tables
DJ.Core = {}

DJ.Consts = {}
DJ.Colors = {}
DJ.DejunkDB = {}
DJ.ListManager = {}
DJ.Tools = {}

DJ.Dejunker = {}
DJ.Repairer = {}
DJ.MerchantButton = {}

DJ.FramePooler = {}
DJ.FrameFactory = {}
DJ.FrameFader = {}

DJ.BaseFrame = {}
DJ.TitleFrame = {}
DJ.BasicOptionsFrame = {}
DJ.BasicListsFrame = {}
DJ.BasicChildFrame = {}
DJ.TransportChildFrame = {}
