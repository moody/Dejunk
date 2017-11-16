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

function DestroyChildFrame:OnShow()
  DestroyChildOptionsFrame:Show()
  DestroyChildListFrame:Show()
end

function DestroyChildFrame:OnHide()
  DestroyChildOptionsFrame:Hide()
  DestroyChildListFrame:Hide()
end

function DestroyChildFrame:OnEnable()
  DestroyChildOptionsFrame:Enable()
  DestroyChildListFrame:Enable()
end

function DestroyChildFrame:OnDisable()
  DestroyChildOptionsFrame:Disable()
  DestroyChildListFrame:Disable()
end

function DestroyChildFrame:OnRefresh()
  DestroyChildOptionsFrame:Refresh()
  DestroyChildListFrame:Refresh()
end

function DestroyChildFrame:OnResize()
  DestroyChildOptionsFrame:Resize()
  DestroyChildListFrame:Resize()

  local newWidth = DestroyChildOptionsFrame:GetWidth() + DestroyChildListFrame:GetWidth() - Tools:Padding()
  local newHeight = max(DestroyChildOptionsFrame:GetHeight(), DestroyChildListFrame:GetHeight())

  DestroyChildOptionsFrame:SetHeight(newHeight)
  DestroyChildListFrame:SetHeight(newHeight)

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end
