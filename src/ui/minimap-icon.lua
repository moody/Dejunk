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
        Commands.options()
      end

      if button == "RightButton" then
        if IsShiftKeyDown() then
          Sounds.Click()
          Commands.destroy()
        else
          Commands.junk()
        end
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Addon.VERSION)
      tooltip:AddDoubleLine(L.LEFT_CLICK, Colors.White(L.TOGGLE_OPTIONS_FRAME))
      tooltip:AddDoubleLine(L.RIGHT_CLICK, Colors.White(L.TOGGLE_JUNK_FRAME))
      tooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, Colors.White(L.DESTROY_NEXT_ITEM))
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
