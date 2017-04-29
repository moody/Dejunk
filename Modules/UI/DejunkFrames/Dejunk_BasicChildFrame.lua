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

-- Dejunk_BasicChildFrame: displays the BasicOptionsFrame and BasicListsFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicChildFrame = DJ.DejunkFrames.BasicChildFrame

local Tools = DJ.Tools
local BasicOptionsFrame = DJ.DejunkFrames.BasicOptionsFrame
local BasicListsFrame = DJ.DejunkFrames.BasicListsFrame

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function BasicChildFrame:OnInitialize()
  local ui = self.UI

  BasicOptionsFrame:Initialize()
  BasicOptionsFrame:SetParent(ui.Frame)
  BasicOptionsFrame:SetPoint({"TOPLEFT", ui.Frame})

  BasicListsFrame:Initialize()
  BasicListsFrame:SetParent(ui.Frame)
  BasicListsFrame:SetPoint({"TOPLEFT", BasicOptionsFrame.UI.Frame, "BOTTOMLEFT", 0, -Tools:Padding()})
end

-- @Override
function BasicChildFrame:OnDeinitialize()
  BasicOptionsFrame:Deinitialize()
  BasicListsFrame:Deinitialize()
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = BasicChildFrame.Show

  function BasicChildFrame:Show()
    BasicOptionsFrame:Show()
    BasicListsFrame:Show()
    show(self)
  end
end

do -- Hook Hide
  local hide = BasicChildFrame.Hide

  function BasicChildFrame:Hide()
    BasicOptionsFrame:Hide()
    BasicListsFrame:Hide()
    hide(self)
  end
end

do -- Hook Enable
  local enable = BasicChildFrame.Enable

  function BasicChildFrame:Enable()
    BasicOptionsFrame:Enable()
    BasicListsFrame:Enable()
    enable(self)
  end
end

do -- Hook Disable
  local disable = BasicChildFrame.Disable

  function BasicChildFrame:Disable()
    BasicOptionsFrame:Disable()
    BasicListsFrame:Disable()
    disable(self)
  end
end

do -- Hook Refresh
  local refresh = BasicChildFrame.Refresh

  function BasicChildFrame:Refresh()
    BasicOptionsFrame:Refresh()
    BasicListsFrame:Refresh()
    refresh(self)
  end
end

-- @Override
function BasicChildFrame:Resize()
  BasicOptionsFrame:Resize()
  BasicListsFrame:Resize()

  local newWidth = max(BasicOptionsFrame:GetWidth(), BasicListsFrame:GetWidth())
  local _, newHeight = Tools:Measure(self.UI.Frame,
    BasicOptionsFrame.UI.Frame, BasicListsFrame.UI.Frame, "TOPLEFT", "BOTTOMLEFT")

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetWidth
  local setWidth = BasicChildFrame.SetWidth

  function BasicChildFrame:SetWidth(width)
    BasicOptionsFrame:SetWidth(width)
    BasicListsFrame:SetWidth(width)
    setWidth(self, width)
  end
end
