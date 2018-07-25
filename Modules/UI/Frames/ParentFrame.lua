-- ParentFrame: displays the TitleFrame and a child frame.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Modules
local ParentFrame = Addon.Frames.ParentFrame

local Colors = Addon.Colors

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function ParentFrame:OnInitialize()
  local frame = self.Frame
  frame:SetColors(Colors.ParentFrame, Colors.Border)
  frame:SetPadding(DFL:Padding())
  frame:SetSpacing(DFL:Padding())

  self:SetTitle(Addon.Frames.TitleFrame)
  self:SetContent(Addon.Frames.DejunkChildFrame)
end

function ParentFrame:OnHide()
  Addon.EventManager:Emit("OnParentFrameClosed")
end

function ParentFrame:OnUpdate(elapsed)
  self:SetEnabled(not Addon.Core:IsBusy())
end
