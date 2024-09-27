local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local ReducerFactories = Addon:GetModule("ReducerFactories")
local Wux = Addon.Wux

--- @class Reducers
local Reducers = Addon:GetModule("Reducers")

-- ============================================================================
-- Default States
-- ============================================================================

--- Default state.
--- @class DefaultState
local DEFAULT_STATE = {
  autoJunkFrame = false,
  autoRepair = false,
  autoSell = false,
  safeMode = false,

  excludeEquipmentSets = true,
  excludeUnboundEquipment = false,
  excludeWarbandEquipment = false,

  includeBelowItemLevel = { enabled = false, value = 0 },
  includeByQuality = true,
  includeUnsuitableEquipment = false,
  includeArtifactRelics = false,

  inclusions = { --[[ ["itemId"] = true, ... ]] },
  exclusions = { --[[ ["itemId"] = true, ... ]] },

  itemQualityCheckBoxes = {
    excludeUnboundEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    excludeWarbandEquipment = { poor = true, common = true, uncommon = true, rare = true, epic = true },
    includeByQuality = { poor = true, common = false, uncommon = false, rare = false, epic = false },
  }
}

--- Global default state.
--- @class GlobalState : DefaultState
local GLOBAL_DEFAULT_STATE = Wux:DeepCopy(DEFAULT_STATE)
GLOBAL_DEFAULT_STATE.chatMessages = true
GLOBAL_DEFAULT_STATE.itemIcons = false
GLOBAL_DEFAULT_STATE.itemTooltips = true
GLOBAL_DEFAULT_STATE.merchantButton = true
GLOBAL_DEFAULT_STATE.minimapIcon = { hide = false }
GLOBAL_DEFAULT_STATE.points = {
  mainWindow = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  junkFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  transportFrame = { point = "CENTER", relativePoint = "CENTER", offsetX = 0, offsetY = 50 },
  merchantButton = { point = "TOPLEFT", relativePoint = "TOPLEFT", offsetX = 75, offsetY = -145 }
}

-- Per character default state.
--- @class PercharState : DefaultState
local PERCHAR_DEFAULT_STATE = Wux:DeepCopy(DEFAULT_STATE)
PERCHAR_DEFAULT_STATE.characterSpecificSettings = false

-- ============================================================================
-- Global Saved Variables Reducer
-- ============================================================================

--- @type WuxReducer<GlobalState>
Reducers.globalReducer = Wux:CombineReducers({
  -- Chat messages.
  chatMessages = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.chatMessages)

    if action.type == "global/chatMessages/set" then
      state = action.payload
    end

    return state
  end,

  -- Item icons.
  itemIcons = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.itemIcons)

    if action.type == "global/itemIcons/set" then
      state = action.payload
    end

    return state
  end,

  -- Item tooltips.
  itemTooltips = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.itemTooltips)

    if action.type == "global/itemTooltips/set" then
      state = action.payload
    end

    return state
  end,

  -- Merchant button.
  merchantButton = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.merchantButton)

    if action.type == "global/merchantButton/set" then
      state = action.payload
    end

    return state
  end,

  -- Minimap icon.
  minimapIcon = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.minimapIcon)

    if action.type == "global/minimapIcon/patch" then
      state = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do state[k] = v end
    end

    return state
  end,

  -- Points.
  points = Wux:CombineReducers({
    -- Points -> MainWindow.
    mainWindow = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.mainWindow)

      if action.type == Actions.Types.Global.SET_MAIN_WINDOW_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_MAIN_WINDOW_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.mainWindow)
      end

      return state
    end,
    -- Points -> JunkFrame.
    junkFrame = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.junkFrame)

      if action.type == Actions.Types.Global.SET_JUNK_FRAME_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_JUNK_FRAME_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.junkFrame)
      end

      return state
    end,
    -- Points -> TransportFrame.
    transportFrame = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.transportFrame)

      if action.type == Actions.Types.Global.SET_TRANSPORT_FRAME_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_TRANSPORT_FRAME_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.transportFrame)
      end

      return state
    end,
    -- Points -> MerchantButton.
    merchantButton = function(state, action)
      state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.points.merchantButton)

      if action.type == Actions.Types.Global.SET_MERCHANT_BUTTON_POINT then
        return action.payload
      end

      if action.type == Actions.Types.Global.RESET_MERCHANT_BUTTON_POINT then
        return Wux:ShallowCopy(GLOBAL_DEFAULT_STATE.points.merchantButton)
      end

      return state
    end,
  }),

  -- Auto junk frame.
  autoJunkFrame = ReducerFactories.autoJunkFrame(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Auto repair.
  autoRepair = ReducerFactories.autoRepair(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Auto sell.
  autoSell = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.autoSell)

    if action.type == "global/autoSell/set" then
      state = action.payload
    end

    return state
  end,

  -- Safe mode.
  safeMode = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.safeMode)

    if action.type == "global/safeMode/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude equipment sets.
  excludeEquipmentSets = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.excludeEquipmentSets)

    if action.type == "global/excludeEquipmentSets/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude unbound equipment.
  excludeUnboundEquipment = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.excludeUnboundEquipment)

    if action.type == "global/excludeUnboundEquipment/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude warband equipment.
  excludeWarbandEquipment = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.excludeWarbandEquipment)

    if action.type == Actions.Types.Global.SET_EXCLUDE_WARBAND_EQUIPMENT then
      return action.payload
    end

    return state
  end,

  -- Include below item level.
  includeBelowItemLevel = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.includeBelowItemLevel)

    if action.type == "global/includeBelowItemLevel/patch" then
      state = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do state[k] = v end
    end

    return state
  end,

  -- Include by quality.
  includeByQuality = ReducerFactories.includeByQuality(GLOBAL_DEFAULT_STATE, Actions.Types.Global),

  -- Include unsuitable equipment.
  includeUnsuitableEquipment = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.includeUnsuitableEquipment)

    if action.type == "global/includeUnsuitableEquipment/set" then
      state = action.payload
    end

    return state
  end,

  -- Include artifact relics.
  includeArtifactRelics = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.includeArtifactRelics)

    if action.type == "global/includeArtifactRelics/set" then
      state = action.payload
    end

    return state
  end,

  -- Inclusions.
  inclusions = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.inclusions)

    if action.type == "global/inclusions/set" then
      state = Wux:ShallowCopy(action.payload)
    end

    return state
  end,

  -- Exclusions.
  exclusions = function(state, action)
    state = Wux:Coalesce(state, GLOBAL_DEFAULT_STATE.exclusions)

    if action.type == "global/exclusions/set" then
      state = Wux:ShallowCopy(action.payload)
    end

    return state
  end,

  -- Item quality check boxes.
  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(GLOBAL_DEFAULT_STATE, Actions.Types.Global)
})

-- ============================================================================
-- Per Character Saved Variables Reducer
-- ============================================================================

--- @type WuxReducer<PercharState>
Reducers.percharReducer = Wux:CombineReducers({
  -- Character specific settings.
  characterSpecificSettings = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.characterSpecificSettings)

    if action.type == "perchar/characterSpecificSettings/toggle" then
      state = not state
    end

    return state
  end,

  -- Auto junk frame.
  autoJunkFrame = ReducerFactories.autoJunkFrame(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Auto repair.
  autoRepair = ReducerFactories.autoRepair(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Auto sell.
  autoSell = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.autoSell)

    if action.type == "perchar/autoSell/set" then
      state = action.payload
    end

    return state
  end,

  -- Safe mode.
  safeMode = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.safeMode)

    if action.type == "perchar/safeMode/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude equipment sets.
  excludeEquipmentSets = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.excludeEquipmentSets)

    if action.type == "perchar/excludeEquipmentSets/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude unbound equipment.
  excludeUnboundEquipment = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.excludeUnboundEquipment)

    if action.type == "perchar/excludeUnboundEquipment/set" then
      state = action.payload
    end

    return state
  end,

  -- Exclude warband equipment.
  excludeWarbandEquipment = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.excludeWarbandEquipment)

    if action.type == Actions.Types.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT then
      return action.payload
    end

    return state
  end,

  -- Include below item level.
  includeBelowItemLevel = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.includeBelowItemLevel)

    if action.type == "perchar/includeBelowItemLevel/patch" then
      state = Wux:ShallowCopy(state)
      for k, v in pairs(action.payload) do state[k] = v end
    end

    return state
  end,

  -- Include by quality.
  includeByQuality = ReducerFactories.includeByQuality(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar),

  -- Include unsuitable equipment.
  includeUnsuitableEquipment = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.includeUnsuitableEquipment)

    if action.type == "perchar/includeUnsuitableEquipment/set" then
      state = action.payload
    end

    return state
  end,

  -- Include artifact relics.
  includeArtifactRelics = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.includeArtifactRelics)

    if action.type == "perchar/includeArtifactRelics/set" then
      state = action.payload
    end

    return state
  end,

  -- Inclusions.
  inclusions = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.inclusions)

    if action.type == "perchar/inclusions/set" then
      state = Wux:ShallowCopy(action.payload)
    end

    return state
  end,

  -- Exclusions.
  exclusions = function(state, action)
    state = Wux:Coalesce(state, PERCHAR_DEFAULT_STATE.exclusions)

    if action.type == "perchar/exclusions/set" then
      state = Wux:ShallowCopy(action.payload)
    end

    return state
  end,

  -- Item quality check boxes.
  itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(PERCHAR_DEFAULT_STATE, Actions.Types.Perchar)
})

-- ============================================================================
-- Root Reducer
-- ============================================================================

--- @type WuxReducer<{global: GlobalState, perchar: PercharState}>
Reducers.rootReducer = Wux:CombineReducers({
  global = Reducers.globalReducer,
  perchar = Reducers.percharReducer
})
