-- Dejunk_DestroyChildFrame: displays options for automatically destroying items.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DestroyChildFrame = DJ.DejunkFrames.DestroyChildFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function DestroyChildFrame:OnInitialize()
  local frame = self.Frame
  local ui = self.UI
end

-- @Override
function DestroyChildFrame:Resize()
  local ui = self.UI
end
