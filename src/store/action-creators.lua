local Addon = select(2, ...) ---@type Addon
local ActionTypes = Addon:GetModule("ActionTypes")
local Wux = Addon.Wux

--- @class ActionCreators
local ActionCreators = Addon:GetModule("ActionCreators")

-- ============================================================================
-- ActionCreators - Global
-- ============================================================================

ActionCreators.Global = {
  --- Action creator for `ActionTypes.Global.SET_AUTO_JUNK_FRAME`.
  --- @type WuxActionCreator<boolean>
  setAutoJunkFrame = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_JUNK_FRAME),

  --- Action creator for `ActionTypes.Global.SET_AUTO_REPAIR`.
  --- @type WuxActionCreator<boolean>
  setAutoRepair = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_REPAIR),

  --- Action creator for `ActionTypes.Global.SET_AUTO_SELL`.
  --- @type WuxActionCreator<boolean>
  setAutoSell = Wux:CreateActionCreator(ActionTypes.Global.SET_AUTO_SELL),

  --- Action creator for `ActionTypes.Global.SET_CHAT_MESSAGES`.
  --- @type WuxActionCreator<boolean>
  setChatMessages = Addon.Wux:CreateActionCreator(ActionTypes.Global.SET_CHAT_MESSAGES),

  --- Action creator for `ActionTypes.Global.SET_ITEM_ICONS`.
  --- @type WuxActionCreator<boolean>
  setItemIcons = Wux:CreateActionCreator(ActionTypes.Global.SET_ITEM_ICONS),

  --- Action creator for `ActionTypes.Global.SET_ITEM_TOOLTIPS`.
  --- @type WuxActionCreator<boolean>
  setItemTooltips = Wux:CreateActionCreator(ActionTypes.Global.SET_ITEM_TOOLTIPS),

  --- Action creator for `ActionTypes.Global.SET_MERCHANT_BUTTON`.
  --- @type WuxActionCreator<boolean>
  setMerchantButton = Wux:CreateActionCreator(ActionTypes.Global.SET_MERCHANT_BUTTON),

  --- Action creator for `ActionTypes.Global.PATCH_MINIMAP_ICON`.
  --- @type WuxActionCreator<table<string, any>>
  patchMinimapIcon = Wux:CreateActionCreator(ActionTypes.Global.PATCH_MINIMAP_ICON),

  --- Action creator for `ActionTypes.Global.SET_SAFE_MODE`.
  --- @type WuxActionCreator<boolean>
  setSafeMode = Wux:CreateActionCreator(ActionTypes.Global.SET_SAFE_MODE),

  --- Action creator for `ActionTypes.Global.SET_INCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setInclusions = Wux:CreateActionCreator(ActionTypes.Global.SET_INCLUSIONS),

  --- Action creator for `ActionTypes.Global.SET_EXCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setExclusions = Wux:CreateActionCreator(ActionTypes.Global.SET_EXCLUSIONS),

  points = {
    mainWindow = {
      --- Action creator for `ActionTypes.Global.SET_MAIN_WINDOW_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_MAIN_WINDOW_POINT),

      --- Action creator for `ActionTypes.Global.RESET_MAIN_WINDOW_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_MAIN_WINDOW_POINT)
    },

    junkFrame = {
      --- Action creator for `ActionTypes.Global.SET_JUNK_FRAME_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_JUNK_FRAME_POINT),

      --- Action creator for `ActionTypes.Global.RESET_JUNK_FRAME_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_JUNK_FRAME_POINT)
    },

    transportFrame = {
      --- Action creator for `ActionTypes.Global.SET_TRANSPORT_FRAME_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_TRANSPORT_FRAME_POINT),

      --- Action creator for `ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_TRANSPORT_FRAME_POINT)
    },

    merchantButton = {
      --- Action creator for `ActionTypes.Global.SET_MERCHANT_BUTTON_POINT`.
      --- @type WuxActionCreator<table>
      set = Wux:CreateActionCreator(ActionTypes.Global.SET_MERCHANT_BUTTON_POINT),

      --- Action creator for `ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT`.
      --- @type fun(): WuxAction
      reset = Wux:CreateActionCreator(ActionTypes.Global.RESET_MERCHANT_BUTTON_POINT)
    }
  }
}

-- ============================================================================
-- ActionCreators - Perchar
-- ============================================================================

ActionCreators.Perchar = {
  --- Action creator for `ActionTypes.Perchar.SET_EXCLUDE_EQUIPMENT_SETS`.
  --- @type WuxActionCreator<boolean>
  setExcludeEquipmentSets = Wux:CreateActionCreator(ActionTypes.Perchar.SET_EXCLUDE_EQUIPMENT_SETS),

  --- Action creator for `ActionTypes.Perchar.SET_EXCLUDE_UNBOUND_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setExcludeUnboundEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.SET_EXCLUDE_UNBOUND_EQUIPMENT),

  --- Action creator for `ActionTypes.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setExcludeWarbandEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.SET_EXCLUDE_WARBAND_EQUIPMENT),

  --- Action creator for `ActionTypes.Perchar.SET_INCLUDE_ARTIFACT_RELICS`.
  --- @type WuxActionCreator<boolean>
  setIncludeArtifactRelics = Wux:CreateActionCreator(ActionTypes.Perchar.SET_INCLUDE_ARTIFACT_RELICS),

  --- Action creator for `ActionTypes.Perchar.PATCH_INCLUDE_BELOW_ITEM_LEVEL`.
  --- @type WuxActionCreator<table<string, any>>
  patchIncludeBelowItemLevel = Wux:CreateActionCreator(ActionTypes.Perchar.PATCH_INCLUDE_BELOW_ITEM_LEVEL),

  --- Action creator for `ActionTypes.Perchar.SET_INCLUDE_BY_QUALITY`.
  --- @type WuxActionCreator<boolean>
  setIncludeByQuality = Wux:CreateActionCreator(ActionTypes.Perchar.SET_INCLUDE_BY_QUALITY),

  --- Action creator for `ActionTypes.Perchar.SET_INCLUDE_UNSUITABLE_EQUIPMENT`.
  --- @type WuxActionCreator<boolean>
  setIncludeUnsuitableEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.SET_INCLUDE_UNSUITABLE_EQUIPMENT),

  --- Action creator for `ActionTypes.Perchar.SET_INCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setInclusions = Wux:CreateActionCreator(ActionTypes.Perchar.SET_INCLUSIONS),

  --- Action creator for `ActionTypes.Perchar.SET_EXCLUSIONS`.
  --- @type WuxActionCreator<ItemIdMap>
  setExclusions = Wux:CreateActionCreator(ActionTypes.Perchar.SET_EXCLUSIONS),

  itemQualityCheckBoxes = {
    --- Action creator for `ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    excludeUnboundEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_UNBOUND_EQUIPMENT),

    --- Action creator for `ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    excludeWarbandEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_EXCLUDE_WARBAND_EQUIPMENT),

    --- Action creator for `ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeBelowItemLevel = Wux:CreateActionCreator(ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BELOW_ITEM_LEVEL),

    --- Action creator for `ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeByQuality = Wux:CreateActionCreator(ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_BY_QUALITY),

    --- Action creator for `ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT`.
    --- @type WuxActionCreator<ItemQualityCheckBoxValues>
    includeUnsuitableEquipment = Wux:CreateActionCreator(ActionTypes.Perchar.ItemQualityCheckBoxes.PATCH_INCLUDE_UNSUITABLE_EQUIPMENT)
  }
}
