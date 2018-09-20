-- ProfileChildFrame: displays profiles.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Modules
local ProfileChildFrame = Addon.Frames.ProfileChildFrame

local Colors = Addon.Colors
local Consts = Addon.Consts
local DB = Addon.DB
local Tools = Addon.Tools

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function ProfileChildFrame:OnInitialize()
  local frame = self.Frame
  frame:SetDirection(DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.5))
  
  -- Add ProfileFrame
  local profileFrame = Addon.Objects.ProfileFrame:Create(frame)
  self.ProfileFrame = profileFrame
  frame:Add(profileFrame)
end

function ProfileChildFrame:OnShow()
  self.ProfileFrame:RefreshData()
end
