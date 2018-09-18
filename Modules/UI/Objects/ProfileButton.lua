-- ProfileButton: a DFL faux scroll frame button for displaying profile data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown =
      IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown

-- Modules
local ProfileButton = Addon.Objects.ProfileButton
local Core = Addon.Core
local Colors = Addon.Colors
local DB = Addon.DB
local ListManager = Addon.ListManager
local ParentFrame = Addon.Frames.ParentFrame
local DejunkChildFrame = Addon.Frames.DejunkChildFrame

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function ProfileButton:Create(parent)
  local button = Addon.Objects.FauxButton:Create(parent)

  button:SetScript("OnUpdate", function(self)
    if self.Data and (self.Data == DB:GetProfileKey()) then
      DFL:AddBorder(self, unpack(Colors.Inclusions))
    else
      DFL:RemoveBorder(self)
    end
  end)

  -- Mixins
  DFL:AddMixins(button, self.Functions)

  return button
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = ProfileButton.Functions

function Functions:OnClick(button, down)
  -- Change profile
  if (button == "LeftButton") then
    DB:SetProfile(self.Data)
    ListManager:Update()
    ParentFrame:SetContent(DejunkChildFrame)
    ParentFrame:Refresh()
    Core:Debug("ProfileButton", format("Set profile to %s.", self.Data))
  elseif (button == "RightButton") then
    -- Delete profile
    if IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() then
      if (self.Data == DB:GetPlayerKey()) then
        Core:Debug("ProfileButton", "Attempt to delete player profile.")
        return
      end
      if (self.Data == DB:GetProfileKey()) then
        Core:Debug("ProfileButton", "Attempt to delete current profile.")
        return
      end
      DB:DeleteProfile(self.Data)
      self:GetParent():GetParent():GetParent():RefreshData()
    -- Copy profile
    elseif IsShiftKeyDown() and not (IsControlKeyDown() or IsAltKeyDown()) then
      if (self.Data == DB:GetProfileKey()) then
        Core:Debug("ProfileButton", "Attempt to copy current profile.")
        return
      end
      DB:CopyProfile(self.Data)
      ListManager:Update()
      Core:Debug("ProfileButton", "Copied profile.")
    end
  end
end

function Functions:OnEnter()
  DFL:ShowTooltip(self, DFL.Anchors.TOP,
    self.Data,
    "Copy:   Shift + Right Click",
    "Delete: Shift Ctrl Alt + Right Click"
  )
end

function Functions:OnRefresh()
  self.Text:SetText(self.Data)
  self.Text:SetTextColor(unpack(Colors.LabelText))
end
