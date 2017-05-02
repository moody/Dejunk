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

-- Dejunk_Texture: contains FrameFactory functions to create and release a texture tailored to Dejunk.

local AddonName, DJ = ...

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//  					    			    Texture Functions
//*******************************************************************
--]]

-- Creates and returns a texture tailored to Dejunk.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param color - the color of the texture [optional]
-- @return - a Dejunk texture
function FrameFactory:CreateTexture(parent, layer, color)
  local texture = FramePooler:CreateTexture(parent, layer)
  texture.FF_ObjectType = "Texture"

  -- Refreshes the texture.
  function texture:Refresh()
    self:SetColorTexture(unpack(Colors:GetColor(self.Color)))
  end

  -- Sets the colors for the texture.
  function texture:SetColors(color)
    self.Color = (color or Colors.None)

    self:Refresh()
  end

  texture:SetColors(color)

  -- Pre-hook Release functions
  local release = texture.Release

  function texture:Release()
    -- Variables
    self.FF_ObjectType = nil
    self.Color = nil

    -- Functions
    self.Refresh = nil
    self.SetColors = nil

    release(self)
  end

  return texture
end

--[[
-- Releases a texture created by FrameFactory.
-- @param texture - the texture to release
function FrameFactory:ReleaseTexture(texture)
  -- Variables
  texture.FF_ObjectType = nil
  texture.Color = nil

  -- Functions
  texture.Refresh = nil
  texture.SetColors = nil

  FramePooler:ReleaseTexture(texture)
end
--]]
