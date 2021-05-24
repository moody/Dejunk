local AddonName, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local E = Addon.Events
local EventManager = Addon.EventManager
local IsAltKeyDown = _G.IsAltKeyDown
local IsShiftKeyDown = _G.IsShiftKeyDown
local L = Addon.Libs.L
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon
local MinimapIcon = Addon.MinimapIcon

-- Initialize once the DB becomes available.
EventManager:Once(E.DatabaseReady, function()
  local object = LDB:NewDataObject(AddonName, {
    type = "data source",
    text = AddonName,
    icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if button == "LeftButton" then
        if IsShiftKeyDown() then
          Commands.sell()
        else
          Commands.toggle()
        end
      end

      if button == "RightButton" then
        if IsShiftKeyDown() then
          Commands.destroy()
        elseif IsAltKeyDown() then
          Commands.destroy("start")
        else
          Commands.destroy("next")
        end
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(
        DCL:ColorString(AddonName, Colors.Primary),
        Addon.VERSION
      )
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_OPTIONS_FRAME, nil, nil, nil, 1, 1, 1)
      tooltip:AddDoubleLine(L.SHIFT_LEFT_CLICK, L.TOGGLE_SELL_FRAME, nil, nil, nil, 1, 1, 1)
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.RIGHT_CLICK, L.DESTROY_NEXT_ITEM, nil, nil, nil, 1, 1, 1)
      tooltip:AddDoubleLine(L.ALT_RIGHT_CLICK, L.START_DESTROYING, nil, nil, nil, 1, 1, 1)
      tooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, L.TOGGLE_DESTROY_FRAME, nil, nil, nil, 1, 1, 1)
		end,
  })

  LDBIcon:Register(AddonName, object, DB.Global.minimapIcon)
end)

-- ============================================================================
-- General Functions
-- ============================================================================

-- Displays the minimap icon.
function MinimapIcon:Show()
  DB.Global.minimapIcon.hide = false
  LDBIcon:Show(AddonName)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  DB.Global.minimapIcon.hide = true
  LDBIcon:Hide(AddonName)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if DB.Global.minimapIcon.hide then
    self:Show()
  else
    self:Hide()
  end
end
