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

-- Dejunk_FrameFactory: contains functions that return UIObjects tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

--[[
//*******************************************************************
//  					    			  UI Table Functions
//*******************************************************************
--]]

-- Enables a table of objects created by FrameFactory.
-- @param ui - the table of objects to be enabled
function FrameFactory:EnableUI(ui)
  for k, v in pairs(ui) do
    assert(type(v.FF_ObjectType) == "string")

    local func = ("Enable"..v.FF_ObjectType)

    if self[func] then
      self[func](self, v)
    elseif v.SetEnabled then
      v:SetEnabled(true)
    end
  end
end

-- Disables a table of objects created by FrameFactory.
-- @param ui - the table of objects to be disabled
function FrameFactory:DisableUI(ui)
  for k, v in pairs(ui) do
    assert(type(v.FF_ObjectType) == "string")

    local func = ("Disable"..v.FF_ObjectType)

    if self[func] then
      self[func](self, v)
    elseif v.SetEnabled then
      v:SetEnabled(false)
    end
  end
end

-- Refreshes a table of objects created by FrameFactory.
-- @param ui - the table of objects to be refreshed
function FrameFactory:RefreshUI(ui)
  for k, v in pairs(ui) do v:Refresh() end
end

-- Releases a table of objects created by FrameFactory.
-- @param ui - the table of objects to be released
function FrameFactory:ReleaseUI(ui)
  for k, v in pairs(ui) do
    assert(type(v.FF_ObjectType) == "string")

    -- This looks ugly, but it just does this: self:func(v)
    -- So, if the object's type is "Frame", self:ReleaseFrame(v) will be called
    -- I'm doing this to avoid coding a tedious if-elseif based on the object's type
    local func = ("Release"..v.FF_ObjectType)
    self[func](self, v)

    ui[k] = nil
  end
end
