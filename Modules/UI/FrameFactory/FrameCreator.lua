-- FrameCreator: contains simple create functions for UIObjects (frames, buttons, textures, etc.).

local AddonName, DJ = ...

-- Upvalues
local CreateFrame = CreateFrame

-- Dejunk
local FrameCreator = DJ.FrameCreator

-- ============================================================================
--                          Frame Creation Function
-- ============================================================================

FrameCreator.FrameCount = 0

-- Returns a frame.
-- @param parent - the parent frame
-- @return - a basic frame
function FrameCreator:CreateFrame(parent)
  self.FrameCount = (self.FrameCount + 1)

  local name = (AddonName.."Frame"..self.FrameCount)
  local frame = CreateFrame("Frame", name, parent)
  frame:Show()

  return frame
end

-- ============================================================================
--                         Button Creation Function
-- ============================================================================

FrameCreator.ButtonCount = 0

-- Returns a button.
-- @param parent - the parent of the button
-- @return - a basic button
function FrameCreator:CreateButton(parent)
  self.ButtonCount = (self.ButtonCount + 1)

  local name = (AddonName.."Button"..self.ButtonCount)
  local button = CreateFrame("Button", name, parent)
  button:RegisterForClicks("LeftButtonUp")
  button:Show()

  return button
end

-- ============================================================================
--                      Check Button Creation Function
-- ============================================================================

FrameCreator.CheckButtonCount = 0

-- Returns a check button.
-- @param parent - the parent of the check button
-- @return - a basic check button
function FrameCreator:CreateCheckButton(parent)
  self.CheckButtonCount = (self.CheckButtonCount + 1)

  local name = (AddonName.."CheckButton"..self.CheckButtonCount)
  local checkButton = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  checkButton:Show()

  return checkButton
end

-- ============================================================================
--                        Texture Creation Function
-- ============================================================================

FrameCreator.TextureCount = 0

-- Returns a texture.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.)
-- @param color - the optional color table of the texture: {r, g, b[, a]}
-- @return - a basic texture
function FrameCreator:CreateTexture(parent, layer, color)
  self.TextureCount = (self.TextureCount + 1)

  local name = (AddonName.."Texture"..self.TextureCount)
  texture = parent:CreateTexture(name, (layer or "BACKGROUND"))

  if color then
    texture:SetColorTexture(unpack(color))
  else
    texture:SetColorTexture(0, 0, 0, 0)
  end

  texture:SetAllPoints()
  texture:Show()

  return texture
end

-- ============================================================================
--                       Font String Creation Function
-- ============================================================================

FrameCreator.FontStringCount = 0

-- Returns a font string.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param font - the font style to inherit [optional]
-- @param color - the color of the font string: {r, g, b[, a]} [optional]
-- @param shadowOffset - the offset of the font string's shadow [optional]
-- @param shadowColor - the color of the font string's shadow [optional]
-- @return - a basic font string
function FrameCreator:CreateFontString(parent, layer, font, color, shadowOffset, shadowColor)
  self.FontStringCount = (self.FontStringCount + 1)

  local name = (AddonName.."FontString"..self.FontStringCount)
  fontString = parent:CreateFontString(name, (layer or "OVERLAY"), (font or "GameFontNormal"))

  if color then fontString:SetTextColor(unpack(color)) end
  if shadowOffset then fontString:SetShadowOffset(unpack(shadowOffset)) end
  if shadowColor then fontString:SetShadowColor(unpack(shadowColor)) end

  fontString:Show()

  return fontString
end

-- ============================================================================
--                       Scroll Frame Creation Function
-- ============================================================================

FrameCreator.ScrollFrameCount = 0

-- Returns a scroll frame.
-- @param parent - the parent frame
-- @return - a basic scroll frame
function FrameCreator:CreateScrollFrame(parent)
  self.ScrollFrameCount = (self.ScrollFrameCount + 1)

  local name = (AddonName.."ScrollFrame"..self.ScrollFrameCount)
  local scrollFrame = CreateFrame("ScrollFrame", name, parent)
  scrollFrame:SetClipsChildren(true)
  scrollFrame:Show()

  return scrollFrame
end

-- ============================================================================
--                          Slider Creation Function
-- ============================================================================

FrameCreator.SliderCount = 0

-- Returns a slider.
-- @param parent - the parent frame
-- @return - a basic slider
function FrameCreator:CreateSlider(parent)
  self.SliderCount = (self.SliderCount + 1)

  local name = (AddonName.."Slider"..self.SliderCount)
  local slider = CreateFrame("Slider", name, parent)
  slider:Show()

  return slider
end

-- ============================================================================
--                        Edit Box Creation Function
-- ============================================================================

FrameCreator.EditBoxCount = 0

-- Returns an edit box.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @param color - the text color [optional]
-- @param maxLetters - the maximum amount of characters [optional]
-- @param numeric - whether or not the edit box only accepts numeric input [optional]
-- @return - a basic edit box
function FrameCreator:CreateEditBox(parent, font, color, maxLetters, numeric)
  self.EditBoxCount = (self.EditBoxCount + 1)

  local name = (AddonName.."EditBox"..self.EditBoxCount)
  local editBox = CreateFrame("EditBox", name, parent)
  editBox:SetFontObject(font or "GameFontNormal")
  editBox:SetMaxLetters(maxLetters or 0)
  editBox:SetNumeric(numeric)
  editBox:SetAutoFocus(false)
  editBox:ClearFocus()

  if color then
    editBox:SetTextColor(unpack(color))
  else
    editBox:SetTextColor(1, 1, 1, 1)
  end

  editBox:Show()

  return editBox
end
