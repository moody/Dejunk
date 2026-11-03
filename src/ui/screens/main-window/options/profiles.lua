local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local Popup = Addon:GetModule("Popup")
local ProfileSummaries = Addon:GetModule("ProfileSummaries")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

--- Number of profiles shown at once.
local PROFILE_CARD_COUNT = 9

--- Most characters listed in the tooltip of a profile. The rest are counted as hidden.
local MAX_LISTED_CHARACTERS = 10

-- ============================================================================
-- Local Functions
-- ============================================================================

--- The tooltip lines and one-line text of each summary. They are built again whenever the summary is.
--- @type table<ProfileSummary, { lines: string[], text: string }>
local formattedSummaries = setmetatable({}, { __mode = "k" })

--- Returns the tooltip lines for the summary, which end with the characters that use the profile, and the details as
--- one line.
--- @param summary ProfileSummary
--- @return string[] lines, string text
local function formatSummary(summary)
  local details = {}
  if summary.autoSell then details[#details + 1] = Colors.Yellow(L.AUTO_SELL_TEXT) end
  details[#details + 1] = L.INCLUSIONS_TEXT .. ": " .. Colors.White(summary.numInclusions)
  details[#details + 1] = L.EXCLUSIONS_TEXT .. ": " .. Colors.White(summary.numExclusions)

  local lines = {}
  for _, detail in ipairs(details) do lines[#lines + 1] = detail end

  local characterKeys = summary.characterKeys
  if #characterKeys > 0 then
    lines[#lines + 1] = L.USED_BY

    local currentCharacterKey = Addon:GetCharacterKey()
    for index, characterKey in ipairs(characterKeys) do
      if index > MAX_LISTED_CHARACTERS then
        lines[#lines + 1] = Colors.Grey(L.COUNT_HIDDEN:format(#characterKeys - MAX_LISTED_CHARACTERS))
        break
      end

      -- The current character is blue.
      local color = characterKey == currentCharacterKey and Colors.Blue or Colors.White
      lines[#lines + 1] = Colors.Grey("- ") .. color(characterKey)
    end
  end

  return lines, table.concat(details, " · ")
end

--- Returns the tooltip lines that describe the profile, and the details joined in one line. Both are built again only
--- when the profile or the characters assigned to profiles change.
--- @param profile ProfileState
--- @return string[] lines, string text
local function getProfileDetails(profile)
  local characterMap = StateManager:GetStore():GetState().profiles.characterMap
  local summary = ProfileSummaries:Get(profile, characterMap)
  local formatted = formattedSummaries[summary]

  if not formatted then
    local lines, text = formatSummary(summary)
    formatted = { lines = lines, text = text }
    formattedSummaries[summary] = formatted
  end

  return formatted.lines, formatted.text
end

--- Returns `true` if the profile is the active one.
--- @param profile ProfileState
--- @return boolean
local function isActiveProfile(profile)
  return profile.id == StateManager:GetProfileState().id
end

--- Returns `true` if the profile is the default profile, which cannot be renamed or deleted.
--- @param profile ProfileState
--- @return boolean
local function isDefaultProfile(profile)
  return profile.id == DefaultStates.DEFAULT_PROFILE_ID
end

--- Makes the profile the active one.
--- @param profile ProfileState
local function activateProfile(profile)
  if isActiveProfile(profile) then return end

  StateManager:Dispatch(ActionCreators.Profiles.assignProfile({
    characterKey = Addon:GetCharacterKey(),
    profileId = profile.id
  }))
end

--- Asks for a new name for the profile.
--- @param profile ProfileState
local function renameProfile(profile)
  Popup:GetString({
    initialValue = profile.name,
    text = L.RENAME_PROFILE_POPUP_HELP:format(Colors.Yellow(profile.name)),
    onAccept = function(_, value)
      if value ~= profile.name then
        StateManager:Dispatch(ActionCreators.Profiles.renameProfile({
          profileId = profile.id,
          profileName = value
        }))
      end
    end
  })
end

--- Asks for a name, then creates a copy of the profile and activates it.
--- @param profile ProfileState
local function duplicateProfile(profile)
  Popup:GetString({
    initialValue = profile.name,
    text = L.DUPLICATE_PROFILE_POPUP_HELP:format(Colors.Yellow(profile.name)),
    onAccept = function(_, value)
      StateManager:CreateNewProfile(value, profile.id)
    end
  })
end

--- Asks before resetting the profile to the default settings.
--- @param profile ProfileState
local function resetProfile(profile)
  Popup:Confirm({
    text = L.RESET_PROFILE_POPUP_HELP:format(Colors.Yellow(profile.name)),
    alert = true,
    onAccept = function()
      StateManager:Dispatch(ActionCreators.Profiles.resetProfile({ profileId = profile.id }))
    end
  })
end

--- Asks before deleting the profile.
--- @param profile ProfileState
local function deleteProfile(profile)
  Popup:Confirm({
    text = L.DELETE_PROFILE_POPUP_HELP:format(Colors.Yellow(profile.name)),
    alert = true,
    onAccept = function()
      StateManager:Dispatch(ActionCreators.Profiles.deleteProfile({ profileId = profile.id }))
    end
  })
end

--- Asks for a name, then creates a profile and activates it.
local function createProfile()
  Popup:GetString({
    text = L.NEW_PROFILE_POPUP_HELP,
    onAccept = function(_, value)
      StateManager:CreateNewProfile(value)
    end
  })
end

-- ============================================================================
-- MainWindowOptions - Profiles
-- ============================================================================

--- Creates the panel of profiles.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateProfilesPanel()
  local panel = ComponentFactory:TitledPanel({
    titleText = Colors.Blue(L.PROFILES),
    titleJustify = "LEFT"
  })
  panel.Content:SetGap(Widgets:Padding())

  -- Title shows the active profile.
  EventManager:WaitForFirst(E.StoreCreated, function()
    local function refreshTitle()
      local profileName = StateManager:GetProfileState().name
      panel:SetTitleText(Colors.Blue("%s (%s)"):format(L.PROFILES, Colors.White(profileName)))
    end
    EventManager:On(E.StateUpdated, refreshTitle)
    refreshTitle()
  end)

  panel.Content:AttachComponent(ComponentFactory:Text({
    text = L.PROFILES_DESCRIPTION:format(L.DEFAULT_PROFILE_NAME),
    fontObject = B.FontObjects.Small,
    color = Colors.Grey,
    justifyH = "CENTER"
  }))
  panel.Content:AttachComponent(ComponentFactory:Divider())

  panel.Content:AttachComponent(ComponentFactory:CardList({
    cardCount = PROFILE_CARD_COUNT,
    getEntries = function() return StateManager:GetAllProfiles() end,
    createCard = function()
      return ComponentFactory:ProfileCard({
        isActive = isActiveProfile,
        isProtected = isDefaultProfile,
        getSubtext = function(profile)
          local _, text = getProfileDetails(profile)
          return text
        end,
        onActivate = activateProfile,
        onRename = renameProfile,
        onDuplicate = duplicateProfile,
        onReset = resetProfile,
        onDelete = deleteProfile,
        onUpdateTooltip = function(profile, tooltip)
          tooltip:SetText(profile.name)

          local lines = getProfileDetails(profile)
          for _, line in ipairs(lines) do tooltip:AddLine(line) end

          if not isActiveProfile(profile) then
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine(L.LEFT_CLICK, L.ACTIVATE)
          end
        end
      })
    end,
    setCard = function(card, profile)
      card:SetProfile(profile)
    end
  }))

  -- New profile.
  panel.Content:AddChild({
    height = 30,
    frameFactory = function()
      return Widgets:Button({
        labelText = L.NEW_PROFILE,
        labelColor = Colors.Yellow,
        onClick = createProfile
      })
    end
  })

  return panel
end
