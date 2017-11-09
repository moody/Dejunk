-- Dejunk_FrameCreator: contains simple create functions for UIObjects (frames, buttons, textures, etc.).

local AddonName, DJ = ...

-- Upvalues
local CreateFrame = CreateFrame

-- Dejunk
local FrameCreator = DJ.FrameCreator

--[[
//*******************************************************************
//  					    			    Frame Functions
//*******************************************************************
--]]

FrameCreator.FrameCount = 0

-- Returns a frame from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic frame
function FrameCreator:CreateFrame(parent)
  self.FrameCount = (self.FrameCount + 1)

  local name = (AddonName.."Frame"..self.FrameCount)
  local frame = CreateFrame("Frame", name, parent)
  frame:Show()

  return frame
end

--[[
//*******************************************************************
//  					    			    Button Functions
//*******************************************************************
--]]

FrameCreator.ButtonCount = 0

-- Returns a button from the pool if available or creates a new one if not.
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

--[[
//*******************************************************************
//  					    			Check Button Functions
//*******************************************************************
--]]

FrameCreator.CheckButtonCount = 0

-- Returns a check button from the pool if available or creates a new one if not.
-- @param parent - the parent of the check button
-- @return - a basic check button
function FrameCreator:CreateCheckButton(parent)
  self.CheckButtonCount = (self.CheckButtonCount + 1)

  local name = (AddonName.."CheckButton"..self.CheckButtonCount)
  local checkButton = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  checkButton:Show()

  return checkButton
end

--[[
//*******************************************************************
//  					    			    Texture Functions
//*******************************************************************
--]]

FrameCreator.TextureCount = 0

-- Returns a texture from the pool if available or creates a new one if not.
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

--[[
//*******************************************************************
//  					    			 FontString Functions
//*******************************************************************
--]]

FrameCreator.FontStringCount = 0

-- Returns a font string from the pool if available or creates a new one if not.
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

--[[
//*******************************************************************
//  					    			 ScrollFrame Functions
//*******************************************************************
--]]

FrameCreator.ScrollFrameCount = 0

-- Returns a scroll frame from the pool if available or creates a new one if not.
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

--[[
//*******************************************************************
//  					    			    Slider Functions
//*******************************************************************
--]]

FrameCreator.SliderCount = 0

-- Returns a slider from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic slider
function FrameCreator:CreateSlider(parent)
  self.SliderCount = (self.SliderCount + 1)

  local name = (AddonName.."Slider"..self.SliderCount)
  local slider = CreateFrame("Slider", name, parent)
  slider:Show()

  return slider
end

--[[
//*******************************************************************
//  					    			    EditBox Functions
//*******************************************************************
--]]

FrameCreator.EditBoxCount = 0

-- Returns an edit box from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic edit box
function FrameCreator:CreateEditBox(parent, font, color, maxLetters)
  self.EditBoxCount = (self.EditBoxCount + 1)

  local name = (AddonName.."EditBox"..self.EditBoxCount)
  local editBox = CreateFrame("EditBox", name, parent)
  editBox:SetFontObject(font or "GameFontNormal")
  editBox:SetMaxLetters(maxLetters or 0)
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
