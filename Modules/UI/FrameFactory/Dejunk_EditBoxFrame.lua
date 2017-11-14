-- Dejunk_EditBox: contains FrameFactory functions to create an edit box tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Consts = DJ.Consts
local Tools = DJ.Tools
local FrameCreator = DJ.FrameCreator

--[[
//*******************************************************************
//  					    			    EditBox Functions
//*******************************************************************
--]]

-- NOTE: About getStringWidth...
-- This is pretty hacky? Best I could come up with for doing such a thing though.
-- I needed this to make a decent looking currency input frame for the Destroy options frame.

local sizer = UIParent:CreateFontString("DejunkTextWidthSizer", "BACKGROUND")

-- Approximates the minimum width required to display a number of characters in an edit box.
local function getStringWidth(font, numCharacters, numeric)
  assert(type(font) == "string" and type(numCharacters) == "number")

  -- Make string of characters
  local char = numeric and "9" or "W"
  local text = ""
  for i = 1, (numCharacters + 1) do -- the +1 is for some extra approximated space
    text = text..char end

  -- return font string width
  sizer:SetFontObject(font)
  sizer:SetText(text)
  return sizer:GetStringWidth()
end

-- Creates and returns a frame containing an edit box tailored to Dejunk.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @param maxLetters - the maximum amount of characters [optional]
-- @param numeric - whether or not the edit box only accepts numeric input [optional]
-- @return - a Dejunk edit box frame
function FrameFactory:CreateEditBoxFrame(parent, font, maxLetters, numeric)
  local editBoxFrame = FrameCreator:CreateFrame(parent)
  editBoxFrame.FF_ObjectType = "EditBoxFrame"

  editBoxFrame:SetClipsChildren(true)
  editBoxFrame.Texture = self:CreateTexture(editBoxFrame, nil, Colors.Area)

  local editBox = FrameCreator:CreateEditBox(editBoxFrame, font, nil, maxLetters, numeric)
  editBoxFrame.EditBox = editBox

  editBox:SetPoint("TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
  editBox:SetPoint("BOTTOMRIGHT", -Tools:Padding(0.5), Tools:Padding(0.5))

  editBox:SetScript("OnEscapePressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)
  editBox:SetScript("OnEnterPressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)

  editBox:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
  editBox:SetScript("OnDisable", function(self) self:SetAlpha(0.3) end)

  function editBoxFrame:Resize()
    local _, fontHeight = editBox:GetFont()
    local newHeight = (fontHeight + Tools:Padding())

    local newWidth = (maxLetters ~= nil) and
      (getStringWidth(font, maxLetters, numeric) + Tools:Padding()) or
      Consts.EDIT_BOX_MIN_WIDTH

    self:SetWidth(newWidth)
    self:SetHeight(newHeight)
  end

  function editBoxFrame:Refresh()
    self.Texture:Refresh()
    editBox:SetTextColor(unpack(Colors:GetColor(Colors.LabelText)))
  end

  editBoxFrame:Refresh()

  return editBoxFrame
end
