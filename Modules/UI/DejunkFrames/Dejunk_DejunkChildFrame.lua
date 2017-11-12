-- Dejunk_DejunkChildFrame: combines and displays the BasicOptionsFrame and BasicListsFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DejunkChildFrame = DJ.DejunkFrames.DejunkChildFrame

local Tools = DJ.Tools
local BasicOptionsFrame = DJ.DejunkFrames.BasicOptionsFrame
local BasicListsFrame = DJ.DejunkFrames.BasicListsFrame

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function DejunkChildFrame:OnInitialize()
  BasicOptionsFrame:Initialize()
  BasicOptionsFrame:SetParent(self.Frame)
  BasicOptionsFrame:SetPoint({"TOPLEFT", self.Frame})

  BasicListsFrame:Initialize()
  BasicListsFrame:SetParent(self.Frame)
  BasicListsFrame:SetPoint({"TOPLEFT", BasicOptionsFrame.Frame, "BOTTOMLEFT", 0, -Tools:Padding()})
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = DejunkChildFrame.Show

  function DejunkChildFrame:Show()
    BasicOptionsFrame:Show()
    BasicListsFrame:Show()
    show(self)
  end
end

do -- Hook Hide
  local hide = DejunkChildFrame.Hide

  function DejunkChildFrame:Hide()
    BasicOptionsFrame:Hide()
    BasicListsFrame:Hide()
    hide(self)
  end
end

do -- Hook Enable
  local enable = DejunkChildFrame.Enable

  function DejunkChildFrame:Enable()
    BasicOptionsFrame:Enable()
    BasicListsFrame:Enable()
    enable(self)
  end
end

do -- Hook Disable
  local disable = DejunkChildFrame.Disable

  function DejunkChildFrame:Disable()
    BasicOptionsFrame:Disable()
    BasicListsFrame:Disable()
    disable(self)
  end
end

do -- Hook Refresh
  local refresh = DejunkChildFrame.Refresh

  function DejunkChildFrame:Refresh()
    BasicOptionsFrame:Refresh()
    BasicListsFrame:Refresh()
    refresh(self)
  end
end

-- @Override
function DejunkChildFrame:Resize()
  BasicOptionsFrame:Resize()
  BasicListsFrame:Resize()

  local newWidth = max(BasicOptionsFrame:GetWidth(), BasicListsFrame:GetWidth())
  local _, newHeight = Tools:Measure(self.Frame,
    BasicOptionsFrame.Frame, BasicListsFrame.Frame, "TOPLEFT", "BOTTOMLEFT")

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetWidth
  local setWidth = DejunkChildFrame.SetWidth

  function DejunkChildFrame:SetWidth(width)
    BasicOptionsFrame:SetWidth(width)
    BasicListsFrame:SetWidth(width)
    setWidth(self, width)
  end
end
