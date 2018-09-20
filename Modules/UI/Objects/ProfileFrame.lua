-- ProfileFrame: a DFL faux scroll frame for visually displaying profile data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Addon
local ProfileFrame = Addon.Objects.ProfileFrame
local Colors = Addon.Colors
local DB = Addon.DB
local ListManager = Addon.ListManager

-- ============================================================================
-- Local Functions
-- ============================================================================

local function createProfileButton(parent)
  return Addon.Objects.ProfileButton:Create(parent)
end

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame.
-- @param parent - the parent frame
function ProfileFrame:Create(parent)  
  -- FauxFrame
  local frame = Addon.Objects.FauxFrame:Create(parent, "Profiles", createProfileButton, 10)

  -- Title button
  local titleButton = frame.TitleButton
  titleButton:SetText(L.PROFILES_TEXT)

  -- FauxScrollFrame
  local fsFrame = frame.FSFrame
  fsFrame._objFrame:SetMinWidth(600)
  fsFrame._objFrame:SetLayout(DFL.Layouts.FILL)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = ProfileFrame.Functions

function Functions:RefreshData()
  self.FSFrame:SetData(DB:GetProfileKeys())
end
