-- Texture: contains functions to create a DFL texture.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local pairs, unpack = pairs, unpack

-- Mixins
local Texture = DFL.Texture

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL texture.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
function Texture:Create(parent, layer)
  local texture = DFL.Creator:CreateTexture(parent, layer)
  
  DFL:AddDefaults(texture)
  DFL:AddMixins(texture, self.Functions)

  texture:SetColors()
  texture:Refresh()

  return texture
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = Texture.Functions

function Functions:SetColors(color)
  self._color = color or self._color or DFL.Colors.None
end

function Functions:Refresh()
  self:SetColorTexture(unpack(self._color))
end
