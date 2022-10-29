local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Locale
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon
local SavedVariables = Addon.SavedVariables
local Sounds = Addon.Sounds

EventManager:Once(E.SavedVariablesReady, function()
  local object = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = ADDON_NAME,
    icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if button == "LeftButton" then
        if IsShiftKeyDown() then Commands.sell() else Commands.junk() end
      end

      if button == "RightButton" then
        if IsShiftKeyDown() then Commands.destroy() else Commands.options() end
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Gold(Addon.VERSION))
      tooltip:AddDoubleLine(Colors.Yellow(L.LEFT_CLICK), Colors.White(L.TOGGLE_JUNK_FRAME))
      tooltip:AddDoubleLine(Colors.Yellow(L.RIGHT_CLICK), Colors.White(L.TOGGLE_OPTIONS_FRAME))
      tooltip:AddDoubleLine(Colors.Yellow(L.SHIFT_LEFT_CLICK), Colors.White(L.START_SELLING))
      tooltip:AddDoubleLine(Colors.Yellow(L.SHIFT_RIGHT_CLICK), Colors.White(L.DESTROY_NEXT_ITEM))
    end
  })
  LDBIcon:Register(ADDON_NAME, object, SavedVariables:GetGlobal().minimapIcon)

  -- Update visibility.
  C_Timer.NewTicker(0, function()
    if SavedVariables:Get().minimapIcon.hide then
      LDBIcon:Hide(ADDON_NAME)
    else
      LDBIcon:Show(ADDON_NAME)
    end
  end)
end)
