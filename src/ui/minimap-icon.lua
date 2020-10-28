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

-- Initialize once the DB becomes available.
EventManager:Once(E.DatabaseReady, function()
  local object = LDB:NewDataObject(AddonName, {
    type = "data source",
    text = AddonName,
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
