-- Dejunk_BasicListsFrame: displays the Inclusions and Exclusions lists.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicListsFrame = DJ.DejunkFrames.BasicListsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local ListManager = DJ.ListManager
local FrameFactory = DJ.FrameFactory

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function BasicListsFrame:OnInitialize()
  self:CreateListFrames()
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function BasicListsFrame:Resize()
  local ui = self.UI

  ui.InclusionsFrame:Resize()
  ui.ExclusionsFrame:Resize()

  local newWidth = max(ui.InclusionsFrame:GetMinWidth(), ui.ExclusionsFrame:GetMinWidth())
  newWidth = ((newWidth * 2) + Tools:Padding())

  local newHeight = max(ui.InclusionsFrame:GetHeight(), ui.InclusionsFrame:GetHeight())

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

-- Creates the Inclusions and Exclusions list frames.
function BasicListsFrame:CreateListFrames()
  local ui = self.UI
  local buttonCount = 5
  local listName = nil
  local tooltip = nil

  local baseTooltip = format("%s|n|n%s|n|n%s", L.LIST_FRAME_ADD_TOOLTIP,
    L.LIST_FRAME_REM_TOOLTIP, L.LIST_FRAME_REM_ALL_TOOLTIP)

  -- Inclusions
  listName = ListManager.Inclusions
  tooltip = format("%s|n|n%s", L.INCLUSIONS_TOOLTIP, baseTooltip)

  ui.InclusionsFrame = FrameFactory:CreateListFrame(self.Frame, listName,
    buttonCount, L.INCLUSIONS_TEXT, Colors.Inclusions, Colors.InclusionsHi, tooltip)
  ui.InclusionsFrame:SetPoint("TOPLEFT", Tools:Padding(), 0)
  ui.InclusionsFrame:SetPoint("TOPRIGHT", self.Frame, "TOP", -Tools:Padding(0.5), 0)

  -- Exclusions
  listName = ListManager.Exclusions
  tooltip = format("%s|n|n%s", L.EXCLUSIONS_TOOLTIP, baseTooltip)

  ui.ExclusionsFrame = FrameFactory:CreateListFrame(self.Frame, listName,
    buttonCount, L.EXCLUSIONS_TEXT, Colors.Exclusions, Colors.ExclusionsHi, tooltip)
  ui.ExclusionsFrame:SetPoint("TOPRIGHT", -Tools:Padding(), 0)
  ui.ExclusionsFrame:SetPoint("TOPLEFT", self.Frame, "TOP", Tools:Padding(0.5), 0)
end
