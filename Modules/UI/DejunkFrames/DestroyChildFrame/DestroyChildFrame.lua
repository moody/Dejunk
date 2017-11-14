-- DestroyChildFrame: displays options for automatically destroying items.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DestroyChildFrame = DJ.DejunkFrames.DestroyChildFrame

local DestroyChildOptionsFrame = DJ.DejunkFrames.DestroyChildOptionsFrame
local DestroyChildListFrame = DJ.DejunkFrames.DestroyChildListFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory
local ListManager = DJ.ListManager

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function DestroyChildFrame:OnInitialize()
  local ui = self.UI
  local frame = self.Frame

  -- DestroyChildFrame
  DestroyChildOptionsFrame:Initialize()
  DestroyChildOptionsFrame:SetParent(frame)
  DestroyChildOptionsFrame:SetPoint({"TOPLEFT", frame})

  -- DestroyChildListFrame
  DestroyChildListFrame:Initialize()
  DestroyChildListFrame:SetParent(frame)
  DestroyChildListFrame:SetPoint({"BOTTOMRIGHT", frame})
  DestroyChildListFrame:SetPoint({"BOTTOMLEFT", DestroyChildOptionsFrame.Frame, "BOTTOMRIGHT", -Tools:Padding(), 0})
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = DestroyChildFrame.Show

  function DestroyChildFrame:Show()
    DestroyChildOptionsFrame:Show()
    DestroyChildListFrame:Show()
    show(self)
  end
end

do -- Hook Hide
  local hide = DestroyChildFrame.Hide

  function DestroyChildFrame:Hide()
    DestroyChildOptionsFrame:Hide()
    DestroyChildListFrame:Hide()
    hide(self)
  end
end

do -- Hook Enable
  local enable = DestroyChildFrame.Enable

  function DestroyChildFrame:Enable()
    DestroyChildOptionsFrame:Enable()
    DestroyChildListFrame:Enable()
    enable(self)
  end
end

do -- Hook Disable
  local disable = DestroyChildFrame.Disable

  function DestroyChildFrame:Disable()
    DestroyChildOptionsFrame:Disable()
    DestroyChildListFrame:Disable()
    disable(self)
  end
end

do -- Hook Refresh
  local refresh = DestroyChildFrame.Refresh

  function DestroyChildFrame:Refresh()
    DestroyChildOptionsFrame:Refresh()
    DestroyChildListFrame:Refresh()
    refresh(self)
  end
end

-- @Override
function DestroyChildFrame:Resize()
  DestroyChildOptionsFrame:Resize()
  DestroyChildListFrame:Resize()

  local newWidth = DestroyChildOptionsFrame:GetWidth() + DestroyChildListFrame:GetWidth() - Tools:Padding()
  local newHeight = max(DestroyChildOptionsFrame:GetHeight(), DestroyChildListFrame:GetHeight())

  DestroyChildOptionsFrame:SetHeight(newHeight)
  DestroyChildListFrame:SetHeight(newHeight)

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end
