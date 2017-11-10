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

-- Creates and returns a frame containing an edit box tailored to Dejunk.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @return - a Dejunk edit box frame
function FrameFactory:CreateEditBoxFrame(parent, font, maxLetters)
  local editBoxFrame = FrameCreator:CreateFrame(parent)
  editBoxFrame.FF_ObjectType = "EditBoxFrame"

  editBoxFrame:SetClipsChildren(true)

  editBoxFrame.Texture = self:CreateTexture(editBoxFrame, nil, Colors.Area)

  local editBox = FrameCreator:CreateEditBox(editBoxFrame, font, nil, maxLetters)
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

    self:SetWidth(Consts.EDIT_BOX_MIN_WIDTH)
    self:SetHeight(newHeight)
  end

  function editBoxFrame:Refresh()
    self.Texture:Refresh()
    editBox:SetTextColor(unpack(Colors:GetColor(Colors.LabelText)))
  end

  editBoxFrame:Refresh()

  return editBoxFrame
end
