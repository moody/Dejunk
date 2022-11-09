local ADDON_NAME, Addon = ...
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local LDB = Addon:GetLibrary("LDB")
local LDBIcon = Addon:GetLibrary("LDBIcon")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local SavedVariables = Addon:GetModule("SavedVariables")

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

  function MinimapIcon:IsEnabled()
    return not SavedVariables:GetGlobal().minimapIcon.hide
  end

  function MinimapIcon:SetEnabled(enabled)
    SavedVariables:GetGlobal().minimapIcon.hide = not enabled
    LDBIcon:Refresh(ADDON_NAME)
  end
end)
