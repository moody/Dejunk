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

-- Dejunk_FramePooler: contains simple create and release functions for UI resources (frames, buttons, textures, etc.).

local AddonName, DJ = ...

-- Upvalues
local assert, pairs, pcall, remove = assert, pairs, pcall, table.remove
local CreateFrame, UIParent = CreateFrame, UIParent

-- Dejunk
local FramePooler = DJ.FramePooler

local Tools = DJ.Tools

-- Variables
local ScriptHandlers =
{
  "OnAttributeChanged",
  "OnChar",
  "OnClick",
  "OnDisable",
  "OnDragStart",
  "OnDragStop",
  "OnEnable",
  "OnEnter",
  "OnEnterPressed",
  "OnEscapePressed",
  "OnEvent",
  "OnEditFocusGained",
  "OnEditFocusLost",
  "OnHide",
  "OnKeyDown",
  "OnKeyUp",
  "OnLeave",
  "OnLoad",
  "OnMouseDown",
  "OnMouseUp",
  "OnMouseWheel",
  "OnReceiveDrag",
  "OnShow",
  "OnSizeChanged",
  "OnUpdate"
}

--[[
//*******************************************************************
//  					    			    General Functions
//*******************************************************************
--]]

-- Performs generic reset operations on a specified frame.
-- @param frame - the frame to perform reset operations on
function FramePooler:GenericReset(frame)
  self:ClearAllScripts(frame)

  if frame.SetEnabled then
    frame:SetEnabled(true)
  end

  if frame.SetClipsChildren then
    frame:SetClipsChildren(false)
  end

  frame:SetParent(UIParent)
  frame:ClearAllPoints()
  frame:SetAlpha(1)
  frame:Hide()
end

-- Clears all scripts from the specified frame.
-- @param frame - the frame to clear scripts from
function FramePooler:ClearAllScripts(frame)
  if not frame.SetScript then return end

  for i, script in pairs(ScriptHandlers) do
    local hasScript = pcall(frame.GetScript, frame, script)
    if hasScript then frame:SetScript(script, nil) end
  end
end

--[[
//*******************************************************************
//  					    			    Frame Functions
//*******************************************************************
--]]

FramePooler.FramePool = {}
FramePooler.FrameCount = 0

-- Returns a frame from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic frame
function FramePooler:CreateFrame(parent)
  -- Check the pool for an existing resource
  local frame = remove(self.FramePool)

  if frame then
    frame:Show()
    frame:SetParent(parent)
  else -- create new resource
    self.FrameCount = (self.FrameCount + 1)
    local name = (AddonName.."Frame"..self.FrameCount)
    frame = CreateFrame("Frame", name, parent)
  end

  return frame
end

-- Releases a frame created by FramePooler.
-- @param frame - the frame to release
function FramePooler:ReleaseFrame(frame)
  assert(frame and frame:GetObjectType() == "Frame")

  self.FramePool[#self.FramePool+1] = frame

  -- Reset
  frame:EnableMouse(false)
	frame:SetMovable(false)
  frame:RegisterForDrag() -- no arg disables dragging

  self:GenericReset(frame)
end

--[[
//*******************************************************************
//  					    			    Button Functions
//*******************************************************************
--]]

FramePooler.ButtonPool = {}
FramePooler.ButtonCount = 0

-- Returns a button from the pool if available or creates a new one if not.
-- @param parent - the parent of the button
-- @return - a basic button
function FramePooler:CreateButton(parent)
  -- Check the pool for an existing resource
  local button = remove(self.ButtonPool)

  if button then
    button:Show()
    button:SetParent(parent)
  else -- create new resource
    self.ButtonCount = (self.ButtonCount + 1)
    local name = (AddonName.."Button"..self.ButtonCount)
    button = CreateFrame("Button", name, parent)
  end

  button:RegisterForClicks("LeftButtonUp")

  return button
end

-- Releases a button created by FramePooler.
-- @param button - the button to release
function FramePooler:ReleaseButton(button)
  assert(button and button:GetObjectType() == "Button")

  self.ButtonPool[#self.ButtonPool+1] = button

  -- Reset
  button:RegisterForClicks(nil)

  self:GenericReset(button)
end

--[[
//*******************************************************************
//  					    			Check Button Functions
//*******************************************************************
--]]

FramePooler.CheckButtonPool = {}
FramePooler.CheckButtonCount = 0

-- Returns a check button from the pool if available or creates a new one if not.
-- @param parent - the parent of the check button
-- @return - a basic check button
function FramePooler:CreateCheckButton(parent)
  -- Check the pool for an existing resource
  local checkButton = remove(self.CheckButtonPool)

  if checkButton then
    checkButton:Show()
    checkButton:SetParent(parent)
  else -- create new resource
    self.CheckButtonCount = (self.CheckButtonCount + 1)
    local name = (AddonName.."CheckButton"..self.CheckButtonCount)
    checkButton = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  end

  return checkButton
end

-- Releases a check button created by FramePooler.
-- @param checkButton - the check button to release
function FramePooler:ReleaseCheckButton(checkButton)
  assert(checkButton and checkButton:GetObjectType() == "CheckButton")

  self.CheckButtonPool[#self.CheckButtonPool+1] = checkButton

  -- Reset
  checkButton:SetChecked(false)

  self:GenericReset(checkButton)
end

--[[
//*******************************************************************
//  					    			    Texture Functions
//*******************************************************************
--]]

FramePooler.TexturePool = {}
FramePooler.TextureCount = 0

-- Returns a texture from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.)
-- @param color - the optional color table of the texture: {r, g, b[, a]}
-- @return - a basic texture
function FramePooler:CreateTexture(parent, layer, color)
  -- Check the pool for an existing resource
  local texture = remove(self.TexturePool)

  if texture then
    texture:Show()
    texture:SetParent(parent)
    texture:SetDrawLayer(layer or "BACKGROUND")
  else -- create new resource
    self.TextureCount = (self.TextureCount + 1)
    local name = (AddonName.."Texture"..self.TextureCount)
    texture = parent:CreateTexture(name, (layer or "BACKGROUND"))
  end

  if color then
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
  else
    texture:SetColorTexture(0, 0, 0, 0)
  end

  texture:SetAllPoints()

  return texture
end

-- Releases a texture created by FramePooler.
-- @param texture - the texture to release
function FramePooler:ReleaseTexture(texture)
  assert(texture and texture:GetObjectType() == "Texture")

  self.TexturePool[#self.TexturePool+1] = texture

  -- Reset
  texture:SetTexture(nil)
  texture:SetColorTexture(0, 0, 0, 0)

  self:GenericReset(texture)
end

--[[
//*******************************************************************
//  					    			 FontString Functions
//*******************************************************************
--]]

FramePooler.FontStringPool = {}
FramePooler.FontStringCount = 0

-- Returns a font string from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param font - the font style to inherit [optional]
-- @param color - the color of the font string: {r, g, b[, a]} [optional]
-- @param shadowOffset - the offset of the font string's shadow [optional]
-- @param shadowColor - the color of the font string's shadow [optional]
-- @return - a basic font string
function FramePooler:CreateFontString(parent, layer, font, color, shadowOffset, shadowColor)
  -- Check the pool for an existing resource
  local fontString = remove(self.FontStringPool)

  if fontString then
    fontString:Show()
    fontString:SetParent(parent)
    fontString:SetDrawLayer(layer or "OVERLAY")
    fontString:SetFontObject(font or "GameFontNormal")
  else -- create new resource
    self.FontStringCount = (self.FontStringCount + 1)
    local name = (AddonName.."FontString"..self.FontStringCount)
    fontString = parent:CreateFontString(name, (layer or "OVERLAY"), (font or "GameFontNormal"))
  end

  if color then
    fontString:SetTextColor(unpack(color))
  end

  if shadowOffset then fontString:SetShadowOffset(unpack(shadowOffset)) end
  if shadowColor then fontString:SetShadowColor(unpack(shadowColor)) end

  return fontString
end

-- Releases a font string created by FramePooler.
-- @param fontString - the font string to release
function FramePooler:ReleaseFontString(fontString)
  assert(fontString and fontString:GetObjectType() == "FontString")

  self.FontStringPool[#self.FontStringPool+1] = fontString

  -- Reset
  fontString:SetText("")
  fontString:SetTextColor(1, 1, 1, 1)
  fontString:SetShadowOffset(0, 0)
  fontString:SetShadowColor(0, 0, 0, 1)
  fontString:SetWordWrap(true)
  fontString:SetJustifyH("CENTER")
  fontString:SetJustifyV("CENTER")

  self:GenericReset(fontString)
end

--[[
//*******************************************************************
//  					    			 ScrollFrame Functions
//*******************************************************************
--]]

FramePooler.ScrollFramePool = {}
FramePooler.ScrollFrameCount = 0

-- Returns a scroll frame from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic scroll frame
function FramePooler:CreateScrollFrame(parent)
  -- Check the pool for an existing resource
  local scrollFrame = remove(self.ScrollFramePool)

  if scrollFrame then
    scrollFrame:Show()
    scrollFrame:SetParent(parent)
  else -- create new resource
    self.ScrollFrameCount = (self.ScrollFrameCount + 1)
    local name = (AddonName.."ScrollFrame"..self.ScrollFrameCount)
    scrollFrame = CreateFrame("ScrollFrame", name, parent)
  end

  scrollFrame:SetClipsChildren(true)

  return scrollFrame
end

-- Releases a scroll frame created by FramePooler.
-- @param scrollFrame - the scroll frame to release
function FramePooler:ReleaseScrollFrame(scrollFrame)
  assert(scrollFrame and scrollFrame.SetScrollChild)

  self.ScrollFramePool[#self.ScrollFramePool+1] = scrollFrame

  -- Reset
  self:GenericReset(scrollFrame)
end

--[[
//*******************************************************************
//  					    			    Slider Functions
//*******************************************************************
--]]

FramePooler.SliderPool = {}
FramePooler.SliderCount = 0

-- Returns a slider from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic slider
function FramePooler:CreateSlider(parent)
  -- Check the pool for an existing resource
  local slider = remove(self.SliderPool)

  if slider then
    slider:Show()
    slider:SetParent(parent)
  else -- create new resource
    self.SliderCount = (self.SliderCount + 1)
    local name = (AddonName.."Slider"..self.SliderCount)
    slider = CreateFrame("Slider", name, parent)
  end

  return slider
end

-- Releases a slider created by FramePooler.
-- @param slider - the slider to release
function FramePooler:ReleaseSlider(slider)
  assert(slider and slider:GetObjectType() == "Slider")

  self.SliderPool[#self.SliderPool+1] = slider

  -- Reset
  slider:SetMinMaxValues(0, 0)
  slider:SetValueStep(0)
  slider:SetValue(0)

  self:GenericReset(slider)
end

--[[
//*******************************************************************
//  					    			    EditBox Functions
//*******************************************************************
--]]

FramePooler.EditBoxPool = {}
FramePooler.EditBoxCount = 0

-- Returns an edit box from the pool if available or creates a new one if not.
-- @param parent - the parent frame
-- @return - a basic edit box
function FramePooler:CreateEditBox(parent, font, color, maxLetters)
  -- Check the pool for an existing resource
  local editBox = remove(self.EditBoxPool)

  if editBox then
    editBox:Show()
    editBox:SetParent(parent)
  else -- create new resource
    self.EditBoxCount = (self.EditBoxCount + 1)
    local name = (AddonName.."EditBox"..self.EditBoxCount)
    editBox = CreateFrame("EditBox", name, parent)
  end

  editBox:SetFontObject(font or "GameFontNormal")
  editBox:SetMaxLetters(maxLetters or 0)
  editBox:SetAutoFocus(false)
  editBox:ClearFocus()

  if color then
    editBox:SetTextColor(unpack(color))
  else
    editBox:SetTextColor(1, 1, 1, 1)
  end

  return editBox
end

-- Releases an edit box created by FramePooler.
-- @param editBox - the edit box to release
function FramePooler:ReleaseEditBox(editBox)
  assert(editBox and editBox:GetObjectType() == "EditBox")

  self.EditBoxPool[#self.EditBoxPool+1] = editBox

  -- Reset
  editBox:SetText("")
  editBox:SetTextColor(1, 1, 1, 1)
  editBox:SetMultiLine(false)
  editBox:SetAutoFocus(false)
  editBox:HighlightText(0, 0)
  editBox:ClearFocus()

  self:GenericReset(editBox)
end
