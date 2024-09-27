local Addon = select(2, ...) ---@type Addon
local Wux = Addon.Wux

--- @class ReducerFactories
local ReducerFactories = Addon:GetModule("ReducerFactories")

-- ============================================================================
-- ReducerFactories - points
-- ============================================================================

--- Returns a new reducer for `points` using the given `defaultState` and `actionTypes`.
--- @param defaultState GlobalState
--- @param actionTypes ActionTypesGlobal
--- @return WuxReducer<table>
function ReducerFactories.points(defaultState, actionTypes)
  return Wux:CombineReducers({
    --- Reducer for `mainWindow`.
    --- @param state table
    --- @param action WuxAction
    mainWindow = function(state, action)
      state = Wux:Coalesce(state, defaultState.points.mainWindow)

      if action.type == actionTypes.SET_MAIN_WINDOW_POINT then
        return action.payload
      end

      if action.type == actionTypes.RESET_MAIN_WINDOW_POINT then
        return Wux:ShallowCopy(defaultState.points.mainWindow)
      end

      return state
    end,

    --- Reducer for `junkFrame`.
    --- @param state table
    --- @param action WuxAction
    junkFrame = function(state, action)
      state = Wux:Coalesce(state, defaultState.points.junkFrame)

      if action.type == actionTypes.SET_JUNK_FRAME_POINT then
        return action.payload
      end

      if action.type == actionTypes.RESET_JUNK_FRAME_POINT then
        return Wux:ShallowCopy(defaultState.points.junkFrame)
      end

      return state
    end,

    --- Reducer for `transportFrame`.
    --- @param state table
    --- @param action WuxAction
    transportFrame = function(state, action)
      state = Wux:Coalesce(state, defaultState.points.transportFrame)

      if action.type == actionTypes.SET_TRANSPORT_FRAME_POINT then
        return action.payload
      end

      if action.type == actionTypes.RESET_TRANSPORT_FRAME_POINT then
        return Wux:ShallowCopy(defaultState.points.transportFrame)
      end

      return state
    end,

    --- Reducer for `merchantButton`.
    --- @param state table
    --- @param action WuxAction
    merchantButton = function(state, action)
      state = Wux:Coalesce(state, defaultState.points.merchantButton)

      if action.type == actionTypes.SET_MERCHANT_BUTTON_POINT then
        return action.payload
      end

      if action.type == actionTypes.RESET_MERCHANT_BUTTON_POINT then
        return Wux:ShallowCopy(defaultState.points.merchantButton)
      end

      return state
    end,
  })
end
