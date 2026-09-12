local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class RootReducer
local RootReducer = Addon:GetModule("RootReducer")

--- @class DejunkRootState
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
    autoJunkFrame = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_AUTO_JUNK_FRAME, DefaultStates.Profile.settings.autoJunkFrame),
    autoRepair = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_AUTO_REPAIR, DefaultStates.Profile.settings.autoRepair),
    autoSell = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_AUTO_SELL, DefaultStates.Profile.settings.autoSell),
    safeMode = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_SAFE_MODE, DefaultStates.Profile.settings.safeMode),

    excludeEquipmentSets = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUDE_EQUIPMENT_SETS, DefaultStates.Profile.settings.excludeEquipmentSets),
    excludeUnboundEquipment = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUDE_UNBOUND_EQUIPMENT, DefaultStates.Profile.settings.excludeUnboundEquipment),
    excludeWarbandEquipment = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUDE_WARBAND_EQUIPMENT, DefaultStates.Profile.settings.excludeWarbandEquipment),

    includeArtifactRelics = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUDE_ARTIFACT_RELICS, DefaultStates.Profile.settings.includeArtifactRelics),
    includeBelowItemLevel = Wux:CreatePatchReducer(ActionTypes.Profile.PATCH_INCLUDE_BELOW_ITEM_LEVEL, DefaultStates.Profile.settings.includeBelowItemLevel),
    includeByQuality = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUDE_BY_QUALITY, DefaultStates.Profile.settings.includeByQuality),
    includeUnsuitableEquipment = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUDE_UNSUITABLE_EQUIPMENT, DefaultStates.Profile.settings.includeUnsuitableEquipment),

    inclusions = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_INCLUSIONS, DefaultStates.Profile.settings.inclusions),
    exclusions = Wux:CreatePayloadReducer(ActionTypes.Profile.SET_EXCLUSIONS, DefaultStates.Profile.settings.exclusions),

    itemQualityCheckBoxes = Wux:CombineReducers({
      excludeUnboundEquipment = Wux:CreatePatchReducer(
        ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT,
        DefaultStates.Profile.settings.itemQualityCheckBoxes.excludeUnboundEquipment
      ),
      excludeWarbandEquipment = Wux:CreatePatchReducer(
        ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT,
        DefaultStates.Profile.settings.itemQualityCheckBoxes.excludeWarbandEquipment
      ),
      includeBelowItemLevel = Wux:CreatePatchReducer(
        ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL,
        DefaultStates.Profile.settings.itemQualityCheckBoxes.includeBelowItemLevel
      ),
      includeByQuality = Wux:CreatePatchReducer(
        ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY,
        DefaultStates.Profile.settings.itemQualityCheckBoxes.includeByQuality
      ),
      includeUnsuitableEquipment = Wux:CreatePatchReducer(
        ActionTypes.Profile.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT,
        DefaultStates.Profile.settings.itemQualityCheckBoxes.includeUnsuitableEquipment
      )
    })
  })
})

-- ============================================================================
-- RootReducer
-- ============================================================================

--- Builds the root reducer for the store.
--- @return WuxReducer<DejunkRootState, any>
function RootReducer:Build()
  return Wux:CombineReducers({

    --- @type WuxReducer<GlobalState, any>
    global = Wux:CombineReducers({
      chatMessages = Wux:CreatePayloadReducer(ActionTypes.Global.SET_CHAT_MESSAGES, DefaultStates.Global.chatMessages),
      itemIcons = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_ICONS, DefaultStates.Global.itemIcons),
      itemTooltips = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_TOOLTIPS, DefaultStates.Global.itemTooltips),
      merchantButton = Wux:CreatePayloadReducer(ActionTypes.Global.SET_MERCHANT_BUTTON, DefaultStates.Global.merchantButton),
      minimapIcon = Wux:CreatePatchReducer(ActionTypes.Global.PATCH_MINIMAP_ICON, DefaultStates.Global.minimapIcon),

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

        transportFrame = createPointsReducer(
          ActionTypes.Global.SET_TRANSPORT_FRAME_POINT,
          ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT,
          DefaultStates.Global.points.transportFrame
        ),

        merchantButton = createPointsReducer(
          ActionTypes.Global.SET_MERCHANT_BUTTON_POINT,
          ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT,
          DefaultStates.Global.points.merchantButton
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

      -- Assign profile action.
      if action.type == ActionTypes.Profiles.ASSIGN_PROFILE then
        --- @cast action WuxPayloadAction<AssignProfilePayload>
        state = Wux:ShallowCopy(state)
        state.activeProfileId = action.payload.profileId
        state.characterMap = Wux:ShallowCopy(state.characterMap)
        state.characterMap[action.payload.characterKey] = action.payload.profileId
        return state
      end

      -- Delete profile action.
      if action.type == ActionTypes.Profiles.DELETE_PROFILE then
        --- @cast action WuxPayloadAction<DeleteProfilePayload>
        state = Wux:ShallowCopy(state)
        state.profileMap = Wux:ShallowCopy(state.profileMap)
        state.profileMap[action.payload.profileId] = nil
        -- Fall back to the default profile if it was the active one.
        if state.activeProfileId == action.payload.profileId then
          state.activeProfileId = DefaultStates.DEFAULT_PROFILE_ID
        end
        return state
      end

      -- Ensure the active profile is not the default.
      if state.activeProfileId ~= DefaultStates.DEFAULT_PROFILE_ID then
        -- Ensure the active profile exists.
        local profileState = state.profileMap[state.activeProfileId]
        if type(profileState) == "table" then
          -- Run the profile reducer, and update the profile map if the profile changed.
          local newProfileState = profileReducer(profileState, action)
          if newProfileState ~= profileState then
            state = Wux:ShallowCopy(state)
            state.profileMap = Wux:ShallowCopy(state.profileMap)
            state.profileMap[state.activeProfileId] = newProfileState
          end
        end
      end

      return state
    end
  })
end
