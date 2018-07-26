-- FontString: contains functions for a DFL font string.

-- Lib
local DFL = LibStub:GetLibrary("DethsFrameLib-1.0")
if DFL.ALREADY_LOADED then return end

-- Upvalues
local pairs, unpack = pairs, unpack

-- FontString
local FontString = DFL.FontString

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a DFL font string.
-- @param parent - the parent frame
-- @param text - the initial text [optional]
-- @param font - the font style to inherit [optional]
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
function FontString:Create(parent, text, font, layer)
  local fontString = DFL.Creator:CreateFontString(parent, text, font, layer)

  DFL:AddDefaults(fontString)
  DFL:AddMixins(fontString, self.Functions)

  fontString:SetColors()
  fontString:Refresh()

  return fontString
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = FontString.Functions
  
function Functions:SetColors(color, shadowColor)
  self._color = color or self._color or DFL.Colors.Text
  self._shadowColor = shadowColor or self._shadowColor or DFL.Colors.Black
end

function Functions:OnSetEnabled(enabled)
  DFL:SetEnabledAlpha(self, enabled)
end

function Functions:Refresh()
  self:SetTextColor(unpack(self._color))
  self:SetShadowColor(unpack(self._shadowColor))
  
  -- A FontString's alpha gets reset when updating its color
  DFL:SetEnabledAlpha(self, self:IsEnabled())
end
