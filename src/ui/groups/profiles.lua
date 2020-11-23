local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local AceSerializer = _G.LibStub("AceSerializer-3.0")
local Chat = Addon.Chat
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Libs.L
local next = next
local pcall = pcall
local Profiles = Addon.UI.Groups.Profiles
local ProfileVersioner = Addon.ProfileVersioner
local strtrim = _G.strtrim
local Utils = Addon.Utils
local Widgets = Addon.UI.Widgets

-- ============================================================================
-- Helpers
-- ============================================================================

-- Attempts to set the current profile. Returns true if successful.
-- @param {string} key - profile key
local function setProfile(key)
  if DB:SetProfile(key) then
    Chat:Print(
      L.PROFILE_ACTIVATED_TEXT:format(DCL:ColorString(key, Colors.Green))
    )
    EventManager:Fire(E.ProfileChanged)
    return true
  end
  return false
end

-- Attempts to copy from the specified profile. Returns true if successful.
-- @param {string} key - profile key
local function copyProfile(key)
  if DB:CopyProfile(key) then
    Chat:Print(
      L.PROFILE_COPIED_TEXT:format(DCL:ColorString(key, Colors.Yellow))
    )
    EventManager:Fire(E.ProfileChanged)
    return true
  end
  return false
end

-- Attempts to delete the specified profile. Returns true if successful.
-- @param {string} key - profile key
local function deleteProfile(key)
  if DB:DeleteProfile(key) then
    Chat:Print(
      L.PROFILE_DELETED_TEXT:format(DCL:ColorString(key, Colors.Red))
    )
    return true
  end
  return false
end

-- Attempts to create a profile. Returns true if successful.
-- @param {string} key - profile key
-- @param {table} importTable - existing profile data to import
local function createProfile(key, importTable)
  if DB:ProfileExists(key) then
    Chat:Print(
      L.PROFILE_EXISTS_TEXT:format(DCL:ColorString(key, Colors.Yellow))
    )
    return false
  end

  if importTable then
    local valid = pcall(function() ProfileVersioner:Run(importTable) end)
    if not valid then return false end
  end

  if DB:CreateProfile(key, importTable) then
    return setProfile(key)
  end

  return false
end

-- Returns all database profile keys as a kv-pair suitable for AceGUI Dropdowns.
-- @param {boolean} skipCurrent - If true, does not include the current profile
local function getProfileKeys(skipCurrent)
  local keys, currentKey = {}, DB:GetProfileKey()

  for _, key in pairs(DB:GetProfileKeys()) do
    if not (skipCurrent and key == currentKey) then
      keys[key] = key
    end
  end

  return keys
end

-- ============================================================================
-- Profiles
-- ============================================================================

Profiles.parent = "SimpleGroup"
Profiles.layout = "Fill"

function Profiles:Create(parent)
  local tabGroup = AceGUI:Create("TabGroup")
  tabGroup:SetLayout("Fill")
  tabGroup:SetTabs({
    { text = L.PROFILES_TEXT, value = "Profiles" },
    { text = L.IMPORT_PROFILE_TEXT, value = "Import" },
    { text = L.EXPORT_PROFILE_TEXT, value = "Export" }
  })

  tabGroup:SetCallback("OnGroupSelected", function(this, event, group)
    this:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:PauseLayout()

    Profiles[group](Profiles, scrollFrame)

    scrollFrame:ResumeLayout()
    scrollFrame:DoLayout()

    this:AddChild(scrollFrame)
  end)

  tabGroup:SelectTab("Profiles")
  parent:AddChild(tabGroup)

  -- Required to switch tabs when importing
  self.tabGroup = tabGroup
end

function Profiles:Profiles(parent)
  Widgets:Heading(parent, L.PROFILES_TEXT)

  do -- Create or switch
    local group = Widgets:InlineGroup({
      parent = parent,
      title = L.PROFILE_CREATE_OR_SWITCH_TEXT,
      fullWidth = true
    })

    Widgets:Label({
      parent = group,
      text = L.PROFILE_CREATE_OR_SWITCH_HELP_TEXT,
      fullWidth = true
    })

    -- Create Profile
    Widgets:EditBox({
      parent = group,
      label = L.PROFILE_NEW_TEXT,
      onEnterPressed = function(this, event, key)
        key = strtrim(key)
        if (#key > 0) and createProfile(key) then
          this:SetText("")
          this:ClearFocus()
          Profiles:UpdateDropdowns()
        else
          this:SetFocus()
          this:HighlightText(0)
        end
      end
    })

    -- Existing Profiles
    self.existingProfiles = Widgets:Dropdown({
      parent = group,
      label = L.PROFILE_EXISTING_PROFILES_TEXT,
      onValueChanged = function(_, event, key)
        setProfile(key)
        Profiles:UpdateDropdowns()
      end
    })
  end

  do -- Copy
    local group = Widgets:InlineGroup({
      parent = parent,
      title = L.COPY_TEXT,
      fullWidth = true
    })

    Widgets:Label({
      parent = group,
      text = L.PROFILE_COPY_HELP_TEXT,
      fullWidth = true
    })

    self.copyProfile = Widgets:Dropdown({
      parent = group,
      onValueChanged = function(this, event, key)
        copyProfile(key)
        this:SetValue()
      end
    })
  end

  do -- Delete
    local group = Widgets:InlineGroup({
      parent = parent,
      title = L.DELETE_TEXT,
      fullWidth = true
    })

    Widgets:Label({
      parent = group,
      text = L.PROFILE_DELETE_HELP_TEXT,
      fullWidth = true
    })

    self.deleteProfile = Widgets:Dropdown({
      parent = group,
      onValueChanged = function(_, event, key)
        Utils:YesNoPopup({
          text = L.DELETE_PROFILE_POPUP:format(
            DCL:ColorString(key, Colors.Yellow)
          ),
          onAccept = function() deleteProfile(key) end,
          onHide = function() Profiles:UpdateDropdowns() end
        })
      end
    })
  end

  self:UpdateDropdowns()
end

function Profiles:UpdateDropdowns()
  self.existingProfiles:SetList(getProfileKeys(false))
  self.existingProfiles:SetValue(DB:GetProfileKey())

  local keys = getProfileKeys(true)
  local disabled = next(keys) == nil

  self.copyProfile:SetList(keys)
  self.copyProfile:SetValue(nil)
  self.copyProfile:SetDisabled(disabled)

  self.deleteProfile:SetList(keys)
  self.deleteProfile:SetValue(nil)
  self.deleteProfile:SetDisabled(disabled)
end

function Profiles:Import(parent)
  Widgets:Heading(parent, L.IMPORT_PROFILE_TEXT)
  Widgets:Label({
    parent = parent,
    text = L.IMPORT_PROFILE_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Widgets:MultiLineEditBox({
    parent = parent,
    fullWidth = true,
    numLines = 25
  })

  local profileName = Widgets:EditBox({
    parent = parent,
    label = L.PROFILE_NAME_TEXT,
    disableButton = true
  })

  Widgets:Button({
    parent = parent,
    text = L.IMPORT_TEXT,
    onClick = function()
      editBox:ClearFocus()
      profileName:ClearFocus()

      -- Get profile key
      local key = strtrim(profileName:GetText())
      if #key <= 0 then
        profileName:SetFocus()
        return
      end

      -- Deserialize profile
      local status, profile = AceSerializer:Deserialize(editBox:GetText())
      if status and profile and createProfile(key, profile) then
        Profiles.tabGroup:SelectTab("Profiles")
      else
        Chat:Print(L.PROFILE_INVALID_IMPORT_TEXT)
      end
    end
  })
end

function Profiles:Export(parent)
  Widgets:Heading(parent, L.EXPORT_PROFILE_TEXT)
  Widgets:Label({
    parent = parent,
    text = L.EXPORT_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Widgets:MultiLineEditBox({
    parent = parent,
    -- text = AceSerializer:Serialize(DB.Profile),
    fullWidth = true,
    numLines = 25
  })

  Widgets:Button({
    parent = parent,
    text = L.EXPORT_TEXT,
    onClick = function()
      editBox:SetText(AceSerializer:Serialize(DB.Profile))
      editBox:HighlightText(0)
      editBox:SetFocus()
    end
  })
end
