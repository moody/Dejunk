-- ListFrame: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Addon
local ListFrame = Addon.Objects.ListFrame
ListFrame.Scripts = {}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame.
function ListFrame:Create(parent, listName)
  local frame = DFL.Frame:Create(parent,
      DFL.Alignments.TOP, DFL.Directions.DOWN)
  frame:SetSpacing(Tools:Padding(0.5))

  -- Mixins
  frame:AddMixins(frame, self.Functions)

  return frame
end
