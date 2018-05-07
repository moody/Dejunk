-- ParentFrame: displays the TitleFrame and a child frame.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L

local DFL = Addon.Libs.DFL
local Factory = DFL.Factory
local Tools = DFL.Tools

-- Dejunk
local ParentFrame = Addon.Frames.ParentFrame

-- local Colors = Addon.Colors

-- ============================================================================
--                          Frame Lifecycle Functions
-- ============================================================================

function ParentFrame:OnInitialize()
  local frame = self.Frame
  -- frame:SetColors(Colors.ParentFrame, Colors.ScrollFrame)
  frame:SetPadding(Tools:Padding())
  frame:SetSpacing(Tools:Padding())

  self:SetTitle(Addon.Frames.TitleFrame)
  self:SetContent(Addon.Frames.DejunkChildFrame)
end
