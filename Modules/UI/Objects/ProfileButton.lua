-- ProfileButton: a DFL faux scroll frame button for displaying profile data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local GameTooltip, IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown =
      GameTooltip, IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown

-- Modules
local ProfileButton = Addon.Objects.ProfileButton
ProfileButton.Scripts = {}

local Core = Addon.Core
local Colors = Addon.Colors
local DB = Addon.DB
local ListManager = Addon.ListManager
local ParentFrame = Addon.Frames.ParentFrame
local DejunkChildFrame = Addon.Frames.DejunkChildFrame
local ProfileChildFrame = Addon.Frames.ProfileChildFrame

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function ProfileButton:Create(parent)
  local button = Addon.Objects.FauxButton:Create(parent)

  -- Mixins
  DFL:AddMixins(button, self.Functions)
  DFL:AddScripts(button, self.Scripts)

  return button
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ProfileButton.Functions

  function Functions:OnClick(button, down)
    if (button == "LeftButton") then
      -- Change profile
      if DB:SetProfile(self.Data) then
        ListManager:Update()
        ProfileChildFrame.ProfileFrame:RefreshData()
        Core:Print(format(L.PROFILE_ACTIVATED_TEXT, DCL:ColorString(self.Text:GetText(), Colors.Exclusions)))
      end
    elseif (button == "RightButton") then
      -- Delete profile
      if IsShiftKeyDown() and IsAltKeyDown() and not IsControlKeyDown() then
        if DB:DeleteProfile(self.Data) then
          ProfileChildFrame.ProfileFrame:RefreshData()
          Core:Print(format(L.PROFILE_DELETED_TEXT, DCL:ColorString(self.Text:GetText(), Colors.Inclusions)))
        end
      -- Copy profile
      elseif IsControlKeyDown() and not (IsShiftKeyDown() or IsAltKeyDown()) then
        if DB:CopyProfile(self.Data) then
          ListManager:Update()
          Core:Print(format(L.PROFILE_COPIED_TEXT, DCL:ColorString(self.Text:GetText(), Colors.Destroyables)))
        end
      end
    end
  end

  function Functions:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(self.Data, 1.0, 0.82, 0)
    if (self.Data ~= DB:GetProfileKey()) then
      GameTooltip:AddDoubleLine(
        DCL:ColorString(L.ACTIVATE_TEXT, Colors.Exclusions),
        DCL:ColorString(L.LEFT_CLICK_TEXT, DCL.CSS.White)
      )
      GameTooltip:AddDoubleLine(
        DCL:ColorString(L.COPY_TEXT, Colors.Destroyables),
        DCL:ColorString(L.PROFILE_COPY_TOOLTIP, DCL.CSS.White)
      )
      GameTooltip:AddDoubleLine(
        DCL:ColorString(L.DELETE_TEXT, Colors.Inclusions),
        DCL:ColorString(L.PROFILE_DELETE_TOOLTIP, DCL.CSS.White)
      )
    else
      GameTooltip:AddLine(L.PROFILE_ACTIVE_TEXT, 1, 1, 1)
    end
    GameTooltip:Show()
  end

  function Functions:OnRefresh()
    self.Text:SetText((self.Data == "Global") and L.GLOBAL_TEXT or self.Data)
    self.Text:SetTextColor(1, 1, 1, 1)
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = ProfileButton.Scripts

  function Scripts:OnUpdate(elapsed)
    if self.Data and (self.Data == DB:GetProfileKey()) then
      DFL:AddBorder(self, unpack(Colors.Green))
    else
      DFL:RemoveBorder(self)
    end
  end
end
