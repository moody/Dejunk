local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local Wux = Addon.Wux

--- @class RootReducer
local RootReducer = Addon:GetModule("RootReducer")

--- @class DejunkRootState
--- @field global GlobalState
--- @field perchar PercharState

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

-- ============================================================================
-- RootReducer
-- ============================================================================

--- Builds the root reducer for the store.
--- @return WuxReducer<DejunkRootState, any>
function RootReducer:Build()
  return Wux:CombineReducers({

    --- @type WuxReducer<GlobalState, any>
    global = Wux:CombineReducers({
      autoJunkFrame = Wux:CreatePayloadReducer(ActionTypes.Global.SET_AUTO_JUNK_FRAME, DefaultStates.Global.autoJunkFrame),
      autoRepair = Wux:CreatePayloadReducer(ActionTypes.Global.SET_AUTO_REPAIR, DefaultStates.Global.autoRepair),
      autoSell = Wux:CreatePayloadReducer(ActionTypes.Global.SET_AUTO_SELL, DefaultStates.Global.autoSell),
      chatMessages = Wux:CreatePayloadReducer(ActionTypes.Global.SET_CHAT_MESSAGES, DefaultStates.Global.chatMessages),
      itemIcons = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_ICONS, DefaultStates.Global.itemIcons),
      itemTooltips = Wux:CreatePayloadReducer(ActionTypes.Global.SET_ITEM_TOOLTIPS, DefaultStates.Global.itemTooltips),
      merchantButton = Wux:CreatePayloadReducer(ActionTypes.Global.SET_MERCHANT_BUTTON, DefaultStates.Global.merchantButton),
      minimapIcon = Wux:CreatePatchReducer(ActionTypes.Global.PATCH_MINIMAP_ICON, DefaultStates.Global.minimapIcon),

      safeMode = Wux:CreatePayloadReducer(ActionTypes.Global.SET_SAFE_MODE, DefaultStates.Global.safeMode),

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

    --- @type WuxReducer<PercharState, any>
    perchar = Wux:CombineReducers({
      excludeEquipmentSets = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_EXCLUDE_EQUIPMENT_SETS, DefaultStates.Perchar.excludeEquipmentSets),
      excludeUnboundEquipment = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_EXCLUDE_UNBOUND_EQUIPMENT, DefaultStates.Perchar.excludeUnboundEquipment),
      excludeWarbandEquipment = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT, DefaultStates.Perchar.excludeWarbandEquipment),

      includeArtifactRelics = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_INCLUDE_ARTIFACT_RELICS, DefaultStates.Perchar.includeArtifactRelics),
      includeBelowItemLevel = Wux:CreatePatchReducer(ActionTypes.Perchar.PATCH_INCLUDE_BELOW_ITEM_LEVEL, DefaultStates.Perchar.includeBelowItemLevel),
      includeByQuality = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_INCLUDE_BY_QUALITY, DefaultStates.Perchar.includeByQuality),
      includeUnsuitableEquipment = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_INCLUDE_UNSUITABLE_EQUIPMENT, DefaultStates.Perchar.includeUnsuitableEquipment),

      inclusions = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_INCLUSIONS, DefaultStates.Perchar.inclusions),
      exclusions = Wux:CreatePayloadReducer(ActionTypes.Perchar.SET_EXCLUSIONS, DefaultStates.Perchar.exclusions),

      itemQualityCheckBoxes = Wux:CombineReducers({
        excludeUnboundEquipment = Wux:CreatePatchReducer(
          ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT,
          DefaultStates.Perchar.itemQualityCheckBoxes.excludeUnboundEquipment
        ),
        excludeWarbandEquipment = Wux:CreatePatchReducer(
          ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT,
          DefaultStates.Perchar.itemQualityCheckBoxes.excludeWarbandEquipment
        ),
        includeBelowItemLevel = Wux:CreatePatchReducer(
          ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL,
          DefaultStates.Perchar.itemQualityCheckBoxes.includeBelowItemLevel
        ),
        includeByQuality = Wux:CreatePatchReducer(
          ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY,
          DefaultStates.Perchar.itemQualityCheckBoxes.includeByQuality
        ),
        includeUnsuitableEquipment = Wux:CreatePatchReducer(
          ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT,
          DefaultStates.Perchar.itemQualityCheckBoxes.includeUnsuitableEquipment
        )
      })
    })
  })
end
