-- DejunkChildFrame: combines and displays the DejunkChildOptionsFrame and DejunkChildListsFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DejunkChildFrame = DJ.DejunkFrames.DejunkChildFrame

local Tools = DJ.Tools
local DejunkChildOptionsFrame = DJ.DejunkFrames.DejunkChildOptionsFrame
local DejunkChildListsFrame = DJ.DejunkFrames.DejunkChildListsFrame

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function DejunkChildFrame:OnInitialize()
  DejunkChildOptionsFrame:Initialize()
  DejunkChildOptionsFrame:SetParent(self.Frame)
  DejunkChildOptionsFrame:SetPoint({"TOPLEFT", self.Frame})

  DejunkChildListsFrame:Initialize()
  DejunkChildListsFrame:SetParent(self.Frame)
  DejunkChildListsFrame:SetPoint({"TOPLEFT", DejunkChildOptionsFrame.Frame, "BOTTOMLEFT", 0, -Tools:Padding()})
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = DejunkChildFrame.Show

  function DejunkChildFrame:Show()
    DejunkChildOptionsFrame:Show()
    DejunkChildListsFrame:Show()
    show(self)
  end
end

do -- Hook Hide
  local hide = DejunkChildFrame.Hide

  function DejunkChildFrame:Hide()
    DejunkChildOptionsFrame:Hide()
    DejunkChildListsFrame:Hide()
    hide(self)
  end
end

do -- Hook Enable
  local enable = DejunkChildFrame.Enable

  function DejunkChildFrame:Enable()
    DejunkChildOptionsFrame:Enable()
    DejunkChildListsFrame:Enable()
    enable(self)
  end
end

do -- Hook Disable
  local disable = DejunkChildFrame.Disable

  function DejunkChildFrame:Disable()
    DejunkChildOptionsFrame:Disable()
    DejunkChildListsFrame:Disable()
    disable(self)
  end
end

do -- Hook Refresh
  local refresh = DejunkChildFrame.Refresh

  function DejunkChildFrame:Refresh()
    DejunkChildOptionsFrame:Refresh()
    DejunkChildListsFrame:Refresh()
    refresh(self)
  end
end

-- @Override
function DejunkChildFrame:Resize()
  DejunkChildOptionsFrame:Resize()
  DejunkChildListsFrame:Resize()

  local newWidth = max(DejunkChildOptionsFrame:GetWidth(), DejunkChildListsFrame:GetWidth())
  local _, newHeight = Tools:Measure(self.Frame,
    DejunkChildOptionsFrame.Frame, DejunkChildListsFrame.Frame, "TOPLEFT", "BOTTOMLEFT")

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
    DejunkChildOptionsFrame:SetWidth(width)
    DejunkChildListsFrame:SetWidth(width)
    setWidth(self, width)
  end
end
