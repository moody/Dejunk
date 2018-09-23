-- ProfileFrame: a DFL faux scroll frame for visually displaying profile data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local format, strtrim, tinsert, tremove =
      format, strtrim, table.insert, table.remove

local StaticPopup_Show, ChatEdit_FocusActiveWindow =
      StaticPopup_Show, ChatEdit_FocusActiveWindow

-- Addon
local ProfileFrame = Addon.Objects.ProfileFrame
local Colors = Addon.Colors
local Core = Addon.Core
local DB = Addon.DB
local ListManager = Addon.ListManager
local ProfileChildFrame = Addon.Frames.ProfileChildFrame

-- ============================================================================
-- Popup
-- ============================================================================

do
  local function setProfile(key)
    if DB:ProfileExists(key) then
      Core:Print(format(L.PROFILE_EXISTS_TEXT, DCL:ColorString(key, Colors.Destroyables)))
    elseif DB:CreateProfile(key) then
      DB:SetProfile(key)
      ListManager:Update()
      ProfileChildFrame.ProfileFrame:RefreshData()
      Core:Print(format(L.PROFILE_ACTIVATED_TEXT, DCL:ColorString(key, Colors.Exclusions)))
    end
  end

  -- StaticPopupDialogs["RENAME_GUILD"] for reference
  StaticPopupDialogs["DEJUNK_NEW_PROFILE_POPUP"] = {
    text = L.PROFILE_CREATE_POPUP,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 24,
    OnAccept = function(self)
      local text = strtrim(self.editBox:GetText())
      if (#text > 0) then setProfile(text) end
    end,
    EditBoxOnEnterPressed = function(self)
      local text = strtrim(self:GetParent().editBox:GetText())
      if (#text > 0) then setProfile(text) end
      self:GetParent():Hide()
    end,
    OnShow = function(self)
      self.editBox:SetFocus()
    end,
    OnHide = function(self)
      ChatEdit_FocusActiveWindow()
      self.editBox:SetText("")
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
  }
end

-- ============================================================================
-- Local Functions
-- ============================================================================

local function createProfileButton(parent)
  return Addon.Objects.ProfileButton:Create(parent)
end

local function showCreatePopup()
  StaticPopup_Show("DEJUNK_NEW_PROFILE_POPUP")
end

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk profile frame.
-- @param parent - the parent frame
function ProfileFrame:Create(parent)  
  -- FauxFrame
  local frame = Addon.Objects.FauxFrame:Create(parent, "Profiles", createProfileButton, 10)

  -- Title button
  local titleButton = frame.TitleButton
  titleButton:SetText(L.PROFILES_TEXT)

  -- Add Create Profile button
  local createProfile = DFL.Button:Create(frame, L.PROFILE_CREATE_TEXT, DFL.Fonts.Small)
  createProfile:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  createProfile:SetScript("OnClick", showCreatePopup)
  frame.TransportButtons:Add(createProfile)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = ProfileFrame.Functions

function Functions:RefreshData()
  local keys = DB:GetProfileKeys()
  local playerKey = DB:GetPlayerKey()
  local profileKey = DB:GetProfileKey()
  
  -- Remove "Global" and player key
  for i=#keys, 1, -1 do
    local key = keys[i]
    if (key == "Global") or (key == playerKey) or (key == profileKey) then
      tremove(keys, i)
    end
  end

  -- Add profile key to top
  tinsert(keys, 1, profileKey)
  -- Add "Global" and player key as necessary
  if (profileKey == "Global") then
    tinsert(keys, 2, playerKey)
  elseif (profileKey == playerKey) then
    tinsert(keys, 2, "Global")
  else
    tinsert(keys, 2, "Global")
    tinsert(keys, 3, playerKey)
  end

  self.FSFrame:SetData(keys)
end
