local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class RootReducer
local RootReducer = Addon:GetModule("RootReducer")

--- @class DejunkRootState
--- @field version integer
--- @field global GlobalState
--- @field profiles ProfilesState

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Creates a reducer for `global.points` entries.
--- @generic S
--- @param setActionType string
--- @param resetActionType string
--- @param defaultState S
--- @return WuxReducer<S, any>
local function createPointsReducer(setActionType, resetActionType, defaultState)
  return function(state, action)
    state = Wux:Coalesce(state, defaultState)

    if action.type == setActionType then
      return action.payload
    end

    if action.type == resetActionType then
      return Wux:ShallowCopy(defaultState)
    end

    return state
  end
end

--- @type WuxReducer<ProfileState, any>
local profileReducer = Wux:CombineReducers({
  id = function(state, action) return state end,
  name = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_PROFILE_NAME, DefaultStates.Profile.name),
  settings = Wux:CombineReducers({
    autoRepair = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_AUTO_REPAIR, DefaultStates.Profile.settings.autoRepair),
    autoSell = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_AUTO_SELL, DefaultStates.Profile.settings.autoSell),

    excludeAboveItemLevel = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_EXCLUDE_ABOVE_ITEM_LEVEL, DefaultStates.Profile.settings.excludeAboveItemLevel),
    excludeEquipmentSets = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUDE_EQUIPMENT_SETS, DefaultStates.Profile.settings.excludeEquipmentSets),
    excludeUnboundEquipment = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_EXCLUDE_UNBOUND_EQUIPMENT, DefaultStates.Profile.settings.excludeUnboundEquipment),
    excludeWarbandEquipment = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_EXCLUDE_WARBAND_EQUIPMENT, DefaultStates.Profile.settings.excludeWarbandEquipment),

    includeArtifactRelics = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUDE_ARTIFACT_RELICS, DefaultStates.Profile.settings.includeArtifactRelics),
    includeBelowItemLevel = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_INCLUDE_BELOW_ITEM_LEVEL, DefaultStates.Profile.settings.includeBelowItemLevel),
    includeByQuality = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_INCLUDE_BY_QUALITY, DefaultStates.Profile.settings.includeByQuality),
    includeUnsuitableEquipment = Wux:CreateMergeReducer(ActionTypes.Profile.MERGE_INCLUDE_UNSUITABLE_EQUIPMENT, DefaultStates.Profile.settings.includeUnsuitableEquipment),

    inclusions = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUSIONS, DefaultStates.Profile.settings.inclusions),
    exclusions = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUSIONS, DefaultStates.Profile.settings.exclusions)
  })
})

-- ============================================================================
-- RootReducer
-- ============================================================================

--- Builds the root reducer for the store.
--- @return WuxReducer<DejunkRootState, any>
function RootReducer:Build()
  return Wux:CombineReducers({
    -- Not dispatched; `version` is set by `Migrations:Migrate()` before store creation.
    version = function(state)
      return Wux:Coalesce(state, DefaultStates.CURRENT_VERSION)
    end,

    --- @type WuxReducer<GlobalState, any>
    global = Wux:CombineReducers({
      autoJunkFrame = Wux:CreatePayloadReducer(ActionTypes.Global.SET_AUTO_JUNK_FRAME, DefaultStates.Global.autoJunkFrame),
      chatMessages = Wux:CreatePayloadReducer(ActionTypes.Global.SET_CHAT_MESSAGES, DefaultStates.Global.chatMessages),
      itemIcons = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_ICONS, DefaultStates.Global.itemIcons),
      itemTooltips = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_TOOLTIPS, DefaultStates.Global.itemTooltips),
      merchantButton = Wux:CreatePayloadReducer(ActionTypes.Global.SET_MERCHANT_BUTTON, DefaultStates.Global.merchantButton),
      minimapIcon = Wux:CreatePatchReducer(ActionTypes.Global.PATCH_MINIMAP_ICON, DefaultStates.Global.minimapIcon),
      safeDestroy = Wux:CreatePayloadReducer(ActionTypes.Global.SET_SAFE_DESTROY, DefaultStates.Global.safeDestroy),
      safeSell = Wux:CreatePayloadReducer(ActionTypes.Global.SET_SAFE_SELL, DefaultStates.Global.safeSell),

      inclusions = Wux:CreatePayloadReducer(ActionTypes.Global.SET_INCLUSIONS, DefaultStates.Global.inclusions),
      exclusions = Wux:CreatePayloadReducer(ActionTypes.Global.SET_EXCLUSIONS, DefaultStates.Global.exclusions),

      points = Wux:CombineReducers({
        mainWindow = createPointsReducer(
          ActionTypes.Global.SET_MAIN_WINDOW_POINT,
          ActionTypes.Global.RESET_MAIN_WINDOW_POINT,
          DefaultStates.Global.points.mainWindow
        ),

        junkFrame = createPointsReducer(
          ActionTypes.Global.SET_JUNK_FRAME_POINT,
          ActionTypes.Global.RESET_JUNK_FRAME_POINT,
          DefaultStates.Global.points.junkFrame
        ),

        lootableFrame = createPointsReducer(
          ActionTypes.Global.SET_LOOTABLE_FRAME_POINT,
          ActionTypes.Global.RESET_LOOTABLE_FRAME_POINT,
          DefaultStates.Global.points.lootableFrame
        ),

        transportFrame = createPointsReducer(
          ActionTypes.Global.SET_TRANSPORT_FRAME_POINT,
          ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT,
          DefaultStates.Global.points.transportFrame
        ),

        merchantButton = createPointsReducer(
          ActionTypes.Global.SET_MERCHANT_BUTTON_POINT,
          ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT,
          DefaultStates.Global.points.merchantButton
        ),

        profilesFrame = createPointsReducer(
          ActionTypes.Global.SET_PROFILES_FRAME_POINT,
          ActionTypes.Global.RESET_PROFILES_FRAME_POINT,
          DefaultStates.Global.points.profilesFrame
        )
      })
    }),

    --- @type WuxReducer<ProfilesState, any>
    profiles = function(state, action)
      state = Wux:Coalesce(state, DefaultStates.Profiles)

      -- Ensure expected keys are present.
      if state.activeProfileId == nil or state.characterMap == nil or state.profileMap == nil then
        state = Wux:ShallowCopy(state)
        state.activeProfileId = Wux:Coalesce(state.activeProfileId, DefaultStates.DEFAULT_PROFILE_ID)
        state.characterMap = Wux:Coalesce(state.characterMap, DefaultStates.Profiles.characterMap)
        state.profileMap = Wux:Coalesce(state.profileMap, DefaultStates.Profiles.profileMap)
      end

      -- Create profile action.
      if action.type == ActionTypes.Profiles.CREATE_PROFILE then
        --- @cast action WuxPayloadAction<CreateProfilePayload>
        state = Wux:ShallowCopy(state)
        local profile = Wux:DeepCopy(DefaultStates.Profile)
        profile.id = action.payload.profileId
        profile.name = action.payload.profileName
        state.profileMap = Wux:ShallowCopy(state.profileMap)
        state.profileMap[profile.id] = profile
        return state
      end

      -- Rename profile action. The default profile cannot be renamed.
      if action.type == ActionTypes.Profiles.RENAME_PROFILE then
        --- @cast action WuxPayloadAction<RenameProfilePayload>
        if action.payload.profileId == DefaultStates.DEFAULT_PROFILE_ID then return state end
        state = Wux:ShallowCopy(state)
        state.profileMap = Wux:ShallowCopy(state.profileMap)
        local profile = Wux:ShallowCopy(state.profileMap[action.payload.profileId])
        profile.name = action.payload.profileName
        state.profileMap[action.payload.profileId] = profile
        return state
      end

      -- Delete profile action. The default profile cannot be deleted.
      if action.type == ActionTypes.Profiles.DELETE_PROFILE then
        --- @cast action WuxPayloadAction<DeleteProfilePayload>
        if action.payload.profileId == DefaultStates.DEFAULT_PROFILE_ID then return state end
        state = Wux:ShallowCopy(state)
        state.profileMap = Wux:ShallowCopy(state.profileMap)
        state.profileMap[action.payload.profileId] = nil
        -- Fall back to the default profile for any character assigned to the deleted one.
        state.characterMap = Wux:ShallowCopy(state.characterMap)
        for characterKey, profileId in pairs(state.characterMap) do
          if profileId == action.payload.profileId then
            state.characterMap[characterKey] = DefaultStates.DEFAULT_PROFILE_ID
          end
        end
        if state.activeProfileId == action.payload.profileId then
          state.activeProfileId = DefaultStates.DEFAULT_PROFILE_ID
        end
        return state
      end

      -- Reset profile action: replaces its settings with a deep copy of the
      -- defaults, keeping its own id/name. A no-op if the profile isn't
      -- persisted yet, since it's already at the defaults.
      if action.type == ActionTypes.Profiles.RESET_PROFILE then
        --- @cast action WuxPayloadAction<ResetProfilePayload>
        local existing = state.profileMap[action.payload.profileId]
        if existing == nil then return state end
        state = Wux:ShallowCopy(state)
        state.profileMap = Wux:ShallowCopy(state.profileMap)
        local profile = Wux:DeepCopy(DefaultStates.Profile)
        profile.id = existing.id
        profile.name = existing.name
        state.profileMap[action.payload.profileId] = profile
        return state
      end

      -- Assign profile action. Falls through, rather than returning.
      if action.type == ActionTypes.Profiles.ASSIGN_PROFILE then
        --- @cast action WuxPayloadAction<AssignProfilePayload>
        state = Wux:ShallowCopy(state)
        state.activeProfileId = action.payload.profileId
        state.characterMap = Wux:ShallowCopy(state.characterMap)
        state.characterMap[action.payload.characterKey] = action.payload.profileId
      end

      -- Run the profile reducer against the active profile, writing the
      -- result back into `profileMap` only if something changed. The
      -- default profile starts out unpersisted and falls back to the
      -- shared template here; its first real edit is what creates its
      -- `profileMap` entry. Any other missing active profile id stays a
      -- no-op instead of materializing a phantom profile under a stale id
      -- (`state-manager.lua` already redirects off a deleted profile at
      -- login; this is the last-resort backstop).
      local profileState = state.profileMap[state.activeProfileId]
      if profileState == nil and state.activeProfileId == DefaultStates.DEFAULT_PROFILE_ID then
        profileState = DefaultStates.Profile
      end
      if type(profileState) == "table" then
        local newProfileState = profileReducer(profileState, action)
        if newProfileState ~= profileState then
          state = Wux:ShallowCopy(state)
          state.profileMap = Wux:ShallowCopy(state.profileMap)
          state.profileMap[state.activeProfileId] = newProfileState
        end
      end

      return state
    end
  })
end
