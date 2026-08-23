local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local ReducerFactories = Addon:GetModule("ReducerFactories")
local Reducers = Addon:GetModule("Reducers")
local Wux = Addon.Wux

--- @class RootReducer
local RootReducer = Addon:GetModule("RootReducer")

--- @class DejunkRootState
--- @field global GlobalState
--- @field perchar PercharState

--- Builds the root reducer for the store.
--- @return WuxReducer<DejunkRootState, any>
function RootReducer:Build()
  return Wux:CombineReducers({

    --- @type WuxReducer<GlobalState, any>
    global = Wux:CombineReducers({
      autoJunkFrame = Reducers.Global.autoJunkFrame,
      autoRepair = Reducers.Global.autoRepair,
      autoSell = Reducers.Global.autoSell,
      chatMessages = ReducerFactories.chatMessages(DefaultStates.Global, ActionTypes.Global),
      itemIcons = ReducerFactories.itemIcons(DefaultStates.Global, ActionTypes.Global),
      itemTooltips = ReducerFactories.itemTooltips(DefaultStates.Global, ActionTypes.Global),
      merchantButton = ReducerFactories.merchantButton(DefaultStates.Global, ActionTypes.Global),
      minimapIcon = ReducerFactories.minimapIcon(DefaultStates.Global, ActionTypes.Global),
      safeMode = ReducerFactories.safeMode(DefaultStates.Global, ActionTypes.Global),

      inclusions = ReducerFactories.globalInclusions(),
      exclusions = ReducerFactories.globalExclusions(),

      points = ReducerFactories.points(DefaultStates.Global, ActionTypes.Global),
    }),

    --- @type WuxReducer<PercharState, any>
    perchar = Wux:CombineReducers({
      excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(DefaultStates.Perchar, ActionTypes.Perchar),
      excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(DefaultStates.Perchar, ActionTypes.Perchar),
      excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(DefaultStates.Perchar, ActionTypes.Perchar),

      includeArtifactRelics = ReducerFactories.includeArtifactRelics(DefaultStates.Perchar, ActionTypes.Perchar),
      includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(DefaultStates.Perchar, ActionTypes.Perchar),
      includeByQuality = ReducerFactories.includeByQuality(DefaultStates.Perchar, ActionTypes.Perchar),
      includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(DefaultStates.Perchar, ActionTypes.Perchar),

      inclusions = ReducerFactories.percharInclusions(),
      exclusions = ReducerFactories.percharExclusions(),

      itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(DefaultStates.Perchar, ActionTypes.Perchar)
    })
  })
end
