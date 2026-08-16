local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local DefaultStates = Addon:GetModule("DefaultStates")
local ReducerFactories = Addon:GetModule("ReducerFactories")
local Wux = Addon.Wux

--- @class RootReducer
local RootReducer = Addon:GetModule("RootReducer")

--- Builds the root reducer for the store.
function RootReducer:Build()
  --- @type WuxReducer<GlobalState>
  local globalReducer = Wux:CombineReducers({
    autoJunkFrame = ReducerFactories.autoJunkFrame(DefaultStates.Global, ActionTypes.Global),
    autoRepair = ReducerFactories.autoRepair(DefaultStates.Global, ActionTypes.Global),
    autoSell = ReducerFactories.autoSell(DefaultStates.Global, ActionTypes.Global),
    chatMessages = ReducerFactories.chatMessages(DefaultStates.Global, ActionTypes.Global),
    itemIcons = ReducerFactories.itemIcons(DefaultStates.Global, ActionTypes.Global),
    itemTooltips = ReducerFactories.itemTooltips(DefaultStates.Global, ActionTypes.Global),
    merchantButton = ReducerFactories.merchantButton(DefaultStates.Global, ActionTypes.Global),
    minimapIcon = ReducerFactories.minimapIcon(DefaultStates.Global, ActionTypes.Global),
    safeMode = ReducerFactories.safeMode(DefaultStates.Global, ActionTypes.Global),

    inclusions = ReducerFactories.inclusions(DefaultStates.Global, ActionTypes.Global),
    exclusions = ReducerFactories.exclusions(DefaultStates.Global, ActionTypes.Global),

    points = ReducerFactories.points(DefaultStates.Global, ActionTypes.Global),
  })

  --- @type WuxReducer<PercharState>
  local percharReducer = Wux:CombineReducers({
    excludeEquipmentSets = ReducerFactories.excludeEquipmentSets(DefaultStates.Perchar, ActionTypes.Perchar),
    excludeUnboundEquipment = ReducerFactories.excludeUnboundEquipment(DefaultStates.Perchar, ActionTypes.Perchar),
    excludeWarbandEquipment = ReducerFactories.excludeWarbandEquipment(DefaultStates.Perchar, ActionTypes.Perchar),

    includeArtifactRelics = ReducerFactories.includeArtifactRelics(DefaultStates.Perchar, ActionTypes.Perchar),
    includeBelowItemLevel = ReducerFactories.includeBelowItemLevel(DefaultStates.Perchar, ActionTypes.Perchar),
    includeByQuality = ReducerFactories.includeByQuality(DefaultStates.Perchar, ActionTypes.Perchar),
    includeUnsuitableEquipment = ReducerFactories.includeUnsuitableEquipment(DefaultStates.Perchar, ActionTypes.Perchar),

    inclusions = ReducerFactories.inclusions(DefaultStates.Perchar, ActionTypes.Perchar),
    exclusions = ReducerFactories.exclusions(DefaultStates.Perchar, ActionTypes.Perchar),

    itemQualityCheckBoxes = ReducerFactories.itemQualityCheckBoxes(DefaultStates.Perchar, ActionTypes.Perchar)
  })

  --- @type WuxReducer<{ global: GlobalState, perchar: PercharState }>
  return Wux:CombineReducers({
    global = globalReducer,
    perchar = percharReducer
  })
end
