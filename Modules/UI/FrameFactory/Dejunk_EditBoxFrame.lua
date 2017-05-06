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

-- Dejunk_EditBox: contains FrameFactory functions to create and release an edit box tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Consts = DJ.Consts
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

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
  local editBoxFrame = FramePooler:CreateFrame(parent)
  editBoxFrame.FF_ObjectType = "EditBoxFrame"

  editBoxFrame:SetClipsChildren(true)

  editBoxFrame.Texture = self:CreateTexture(editBoxFrame, nil, Colors.Area)

  local editBox = FramePooler:CreateEditBox(editBoxFrame, font, nil, maxLetters)
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

  -- Pre-hook Release function
  local release = editBoxFrame.Release

  function editBoxFrame:Release()
    -- Objects
    self.Texture:Release()
    self.Texture = nil

    self.EditBox:Release()
    self.EditBox = nil

    -- Variables
    self.FF_ObjectType = nil

    -- Functions
    self.Resize = nil
    self.Refresh = nil

    release(self)
  end

  return editBoxFrame
end
