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
function FrameFactory:CreateEditBoxFrame(parent, font)
  local editBoxFrame = FramePooler:CreateFrame(parent)
  editBoxFrame.FF_ObjectType = "EditBoxFrame"

  editBoxFrame:SetClipsChildren(true)

  editBoxFrame.Texture = self:CreateTexture(editBoxFrame, nil, Colors.Area)

  local editBox = FramePooler:CreateEditBox(editBoxFrame, font)
  editBoxFrame.EditBox = editBox

  editBox:SetPoint("TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
  editBox:SetPoint("BOTTOMRIGHT", -Tools:Padding(0.5), Tools:Padding(0.5))

  editBox:SetScript("OnEscapePressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)
  editBox:SetScript("OnEnterPressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)

  function editBoxFrame:Resize()
    local _, fontHeight = editBox:GetFont()
    local newHeight= (fontHeight + Tools:Padding())

    self:SetWidth(Consts.TEXT_FIELD_MIN_WIDTH)
    self:SetHeight(newHeight)
  end

  function editBoxFrame:Refresh()
    self.Texture:Refresh()
    editBox:SetTextColor(unpack(Colors:GetColor(Colors.LabelText)))
  end

  editBoxFrame:Refresh()

  return editBoxFrame
end

-- Releases an edit box frame created by FrameFactory.
-- @param editBoxFrame - the edit box frame to release
function FrameFactory:ReleaseEditBoxFrame(editBoxFrame)
  -- Objects
  self:ReleaseTexture(editBoxFrame.Texture)
  editBoxFrame.Texture = nil

  FramePooler:ReleaseEditBox(editBoxFrame.EditBox)
  editBoxFrame.EditBox = nil

  -- Variables
  editBoxFrame.FF_ObjectType = nil

  -- Functions
  editBoxFrame.Resize = nil
  editBoxFrame.Refresh = nil

  FramePooler:ReleaseFrame(editBoxFrame)
end
