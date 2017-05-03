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
local pairs, pcall, next = pairs, pcall, next
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

  frame:ClearAllPoints()
  frame:SetParent(UIParent)
  frame:SetWidth(0)
  frame:SetHeight(0)
  frame:SetAlpha(1)
  frame:Hide()

  frame.Release = nil
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
  local pool = self.FramePool
  local frame = next(pool)

  if frame then
    pool[frame] = nil
    frame:SetParent(parent)
  else -- create new resource
    self.FrameCount = (self.FrameCount + 1)
    local name = (AddonName.."Frame"..self.FrameCount)
    frame = CreateFrame("Frame", name, parent)
  end

  -- Releases the object back into the pool.
  function frame:Release()
    self:EnableMouse(false)
    self:SetMovable(false)
    self:RegisterForDrag() -- no arg disables dragging

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  frame:Show()
  return frame
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
  local pool = self.ButtonPool
  local button = next(pool)

  if button then
    pool[button] = nil
    button:SetParent(parent)
  else -- create new resource
    self.ButtonCount = (self.ButtonCount + 1)
    local name = (AddonName.."Button"..self.ButtonCount)
    button = CreateFrame("Button", name, parent)
  end

  button:RegisterForClicks("LeftButtonUp")

  -- Releases the object back into the pool.
  function button:Release()
    self:RegisterForClicks(nil)

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  button:Show()
  return button
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
  local pool = self.CheckButtonPool
  local checkButton = next(pool)

  if checkButton then
    pool[checkButton] = nil
    checkButton:SetParent(parent)
  else -- create new resource
    self.CheckButtonCount = (self.CheckButtonCount + 1)
    local name = (AddonName.."CheckButton"..self.CheckButtonCount)
    checkButton = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  end

  -- Releases the object back into the pool.
  function checkButton:Release()
    self:SetChecked(false)

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  checkButton:Show()
  return checkButton
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
  local pool = self.TexturePool
  local texture = next(pool)

  if texture then
    pool[texture] = nil
    texture:SetParent(parent)
    texture:SetDrawLayer(layer or "BACKGROUND")
  else -- create new resource
    self.TextureCount = (self.TextureCount + 1)
    local name = (AddonName.."Texture"..self.TextureCount)
    texture = parent:CreateTexture(name, (layer or "BACKGROUND"))
  end

  if color then
    texture:SetColorTexture(unpack(color))
  else
    texture:SetColorTexture(0, 0, 0, 0)
  end

  texture:SetAllPoints()

  -- Releases the object back into the pool.
  function texture:Release()
    self:SetTexture(nil)
    self:SetColorTexture(0, 0, 0, 0)

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  texture:Show()
  return texture
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
  local pool = self.FontStringPool
  local fontString = next(pool)

  if fontString then
    pool[fontString] = nil
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

  -- Releases the object back into the pool.
  function fontString:Release()
    self:SetText("")
    self:SetTextColor(1, 1, 1, 1)
    self:SetShadowOffset(0, 0)
    self:SetShadowColor(0, 0, 0, 1)
    self:SetWordWrap(true)
    self:SetJustifyH("CENTER")
    self:SetJustifyV("CENTER")

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  fontString:Show()
  return fontString
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
  local pool = self.ScrollFramePool
  local scrollFrame = next(pool)

  if scrollFrame then
    pool[scrollFrame] = nil
    scrollFrame:SetParent(parent)
  else -- create new resource
    self.ScrollFrameCount = (self.ScrollFrameCount + 1)
    local name = (AddonName.."ScrollFrame"..self.ScrollFrameCount)
    scrollFrame = CreateFrame("ScrollFrame", name, parent)
  end

  scrollFrame:SetClipsChildren(true)

  -- Releases the object back into the pool.
  function scrollFrame:Release()
    FramePooler:GenericReset(self)
    pool[self] = true
  end

  scrollFrame:Show()
  return scrollFrame
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
  local pool = self.SliderPool
  local slider = next(pool)

  if slider then
    pool[slider] = nil
    slider:SetParent(parent)
  else -- create new resource
    self.SliderCount = (self.SliderCount + 1)
    local name = (AddonName.."Slider"..self.SliderCount)
    slider = CreateFrame("Slider", name, parent)
  end

  -- Releases the object back into the pool.
  function slider:Release()
    self:SetMinMaxValues(0, 0)
    self:SetValueStep(0)
    self:SetValue(0)

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  slider:Show()
  return slider
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
  local pool = self.EditBoxPool
  local editBox = next(pool)

  if editBox then
    pool[editBox] = nil
    editBox:SetParent(parent)
    editBox:Show()
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

  -- Releases the object back into the pool.
  function editBox:Release()
    editBox:SetText("")
    editBox:SetMultiLine(false)
    editBox:HighlightText(0, 0)

    FramePooler:GenericReset(self)
    pool[self] = true
  end

  return editBox
end
