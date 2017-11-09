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

-- Dejunk_Frame: contains FrameFactory functions to create and release a frame tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//  					    			    Frame Functions
//*******************************************************************
--]]

-- Creates and returns a frame tailored to Dejunk.
-- @param parent - the parent frame
-- @param color - the color of the frame [optional]
-- @return - a Dejunk frame
function FrameFactory:CreateFrame(parent, color)
  local frame = FramePooler:CreateFrame(parent)
  frame.FF_ObjectType = "Frame"

  -- Refreshes the frame.
  function frame:Refresh()
    if not self.Texture then return end

    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.Color)))
  end

  -- Sets the colors for the frame.
  function frame:SetColors(color)
    self.Color = (color or self.Color or Colors.Black)

    if not self.Texture then
      self.Texture = FramePooler:CreateTexture(self)
    end

    self:Refresh()
  end

  if color then frame:SetColors(color) end

  -- Pre-hook Release function
  local release = frame.Release

  function frame:Release()
    -- Objects
    if self.Texture then
      self.Texture:Release()
      self.Texture = nil
    end

    -- Variables
    self.FF_ObjectType = nil
    self.Color = nil

    -- Functions
    self.Refresh = nil
    self.SetColors = nil

    release(self)
  end

  return frame
end
