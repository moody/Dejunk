-- Dejunk_Frame: contains FrameFactory functions to create a frame tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local FrameCreator = DJ.FrameCreator

--[[
//*******************************************************************
//  					    			    Frame Functions
//*******************************************************************
--]]

-- Creates and returns a frame tailored to Dejunk.
-- @param parent - the parent frame
-- @param color - the color of the frame [optional]
-- @return - a Dejunk frame
function FrameFactory:CreateFrame(parent, color)
  local frame = FrameCreator:CreateFrame(parent)
  frame.FF_ObjectType = "Frame"

  -- Refreshes the frame.
  function frame:Refresh()
    if not self.Texture then return end

    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.Color)))
  end

  -- Sets the colors for the frame.
  function frame:SetColors(color)
    self.Color = (color or self.Color or Colors.Black)

    if not self.Texture then
      self.Texture = FrameCreator:CreateTexture(self)
    end

    self:Refresh()
  end

  if color then frame:SetColors(color) end

  return frame
end
