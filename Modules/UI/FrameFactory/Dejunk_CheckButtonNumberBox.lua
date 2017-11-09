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

-- Dejunk_CheckButtonNumberBox: contains FrameFactory functions to create and release a CheckButton & EditBox combo frame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Upvalues
local abs, tonumber = abs, tonumber

-- Dejunk
local FrameFactory = DJ.FrameFactory

local DejunkDB = DJ.DejunkDB
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//                  CheckButtonNumberBox Functions
//*******************************************************************
--]]

function FrameFactory:CreateCheckButtonNumberBox(parent, size, text, textColor, tooltip, svKey, maxLetters)
  assert(svKey and type(DejunkDB.SV[svKey]) == "table")

  local cbnBox = FramePooler:CreateFrame(parent)
  cbnBox.FF_ObjectType = "CheckButtonNumberBox"

  local checkButton = self:CreateCheckButton(cbnBox, size, text, textColor, tooltip)
  cbnBox.CheckButton = checkButton

  local editBoxFrame = self:CreateEditBoxFrame(cbnBox, checkButton.Text:GetFontObject(), maxLetters)
  cbnBox.EditBoxFrame = editBoxFrame

  -- Initialize points
  checkButton:SetPoint("TOPLEFT")
  editBoxFrame:SetPoint("TOPLEFT", checkButton, "BOTTOMLEFT", Tools:Padding(), 0)

  -- CheckButton
  checkButton:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    DejunkDB.SV[svKey].Enabled = checked
    editBoxFrame.EditBox:SetEnabled(checked)
  end)

  -- EditBox
  editBoxFrame.EditBox:SetScript("OnEditFocusLost", function(self)
    local value = tonumber(self:GetText())
    if value then DejunkDB.SV[svKey].Value = floor(abs(value)) end
    self:SetText(DejunkDB.SV[svKey].Value)
  end)

  -- Gets the minimum width of the frame.
  function cbnBox:GetMinWidth()
    return max(checkButton:GetMinWidth(),
      editBoxFrame:GetWidth() + Tools:Padding())
  end

  -- Gets the minimum height of the frame.
  function cbnBox:GetMinHeight()
    return (checkButton:GetMinHeight() + editBoxFrame:GetHeight())
  end

  -- Resizes the frame.
  function cbnBox:Resize()
    editBoxFrame:Resize()

    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  function cbnBox:Refresh()
    checkButton:Refresh()
    editBoxFrame:Refresh()

    local enabled = DejunkDB.SV[svKey].Enabled
    checkButton:SetChecked(enabled)
    editBoxFrame.EditBox:SetEnabled(enabled)
    editBoxFrame.EditBox:SetText(DejunkDB.SV[svKey].Value)
  end

  cbnBox:Refresh()

  -- -- Pre-hook Release function
  -- local release = cbnBox.Release
  --
  -- function cbnBox:Release()
  --   -- Objects
  --   self.CheckButton:Release()
  --   self.CheckButton = nil
  --
  --   self.EditBoxFrame:Release()
  --   self.EditBoxFrame = nil
  --
  --   -- Variables
  --   self.FF_ObjectType = nil
  --
  --   -- Functions
  --   self.GetMinWidth = nil
  --   self.GetMinHeight = nil
  --   self.Resize = nil
  --   self.Refresh = nil
  --
  --   release(self)
  -- end

  return cbnBox
end

function FrameFactory:EnableCheckButtonNumberBox(cbnBox)
  cbnBox.CheckButton:SetEnabled(true)
  cbnBox.EditBoxFrame.EditBox:SetEnabled(true)
end

function FrameFactory:DisableCheckButtonNumberBox(cbnBox)
  cbnBox.CheckButton:SetEnabled(false)
  cbnBox.EditBoxFrame.EditBox:SetEnabled(false)
end
