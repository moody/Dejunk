-- Dejunk_Texture: contains FrameFactory functions to create a texture tailored to Dejunk.

local AddonName, DJ = ...

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local FrameCreator = DJ.FrameCreator

-- ============================================================================
--                             Creation Function
-- ============================================================================

-- Creates and returns a texture tailored to Dejunk.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param color - the color of the texture [optional]
-- @return - a Dejunk texture
function FrameFactory:CreateTexture(parent, layer, color)
  local texture = FrameCreator:CreateTexture(parent, layer)
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

  return texture
end
