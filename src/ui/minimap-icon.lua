local AddonName, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Destroyer = Addon.Destroyer
local E = Addon.Events
local EventManager = Addon.EventManager
local L = Addon.Libs.L
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon
local MinimapIcon = Addon.MinimapIcon
local UI = Addon.UI

local OBJECT_NAME = AddonName .. "MinimapIcon"

-- Initialize once the DB becomes available.
EventManager:Once(E.DatabaseReady, function()
  local object = LDB:NewDataObject(OBJECT_NAME, {
  	icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if (button == "LeftButton") then
        UI:Toggle()
      elseif (button == "RightButton") then
        Destroyer:Start()
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(
        DCL:ColorString(AddonName, Colors.Primary),
        Addon.VERSION
      )
      tooltip:AddLine(" ")
			tooltip:AddLine(DCL:ColorString(L.MINIMAP_ICON_TOOLTIP_1, DCL.CSS.White))
      tooltip:AddLine(DCL:ColorString(L.MINIMAP_ICON_TOOLTIP_2, DCL.CSS.White))
		end,
  })

  LDBIcon:Register(OBJECT_NAME, object, DB.Global.Minimap)
end)

-- ============================================================================
-- General Functions
-- ============================================================================

-- Displays the minimap icon.
function MinimapIcon:Show()
  DB.Global.Minimap.hide = false
  LDBIcon:Show(OBJECT_NAME)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  DB.Global.Minimap.hide = true
  LDBIcon:Hide(OBJECT_NAME)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if DB.Global.Minimap.hide then
    self:Show()
  else
    self:Hide()
  end
end
