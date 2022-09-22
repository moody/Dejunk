local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Locale
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon
local SavedVariables = Addon.SavedVariables
local UserInterface = Addon.UserInterface

EventManager:Once(E.SavedVariablesReady, function()
  local object = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = ADDON_NAME,
    icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if button == "LeftButton" then
        UserInterface:Toggle()
      end

      if button == "RightButton" then
        Destroyer:Start()
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Addon.VERSION)
      tooltip:AddDoubleLine(L.LEFT_CLICK, Colors.White(L.TOGGLE_USER_INTERFACE))
      tooltip:AddDoubleLine(L.RIGHT_CLICK, Colors.White(L.DESTROY_NEXT_ITEM))
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
