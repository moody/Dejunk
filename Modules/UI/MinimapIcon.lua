-- Dejunk_MinimapIcon: provides a minimap button for Dejunk.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon

-- Modules
local MinimapIcon = Addon.MinimapIcon

local Colors = Addon.Colors
local DejunkDB = Addon.DejunkDB
local Tools = Addon.Tools

-- Variables
local ObjectName = "DejunkMinimapIcon"

-- ============================================================================
--                             Minimap Button
-- ============================================================================

-- Initializes the minimap icon.
function MinimapIcon:Initialize()
  self.LDB = LDB:NewDataObject(ObjectName, {
  	icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if (button == "LeftButton") then
        Addon.Core:ToggleGUI()
      elseif (button == "RightButton") then
        Addon.Destroyer:StartDestroying()
      end
    end,

    OnTooltipShow = function(tooltip)
			tooltip:AddLine(DCL:ColorString(AddonName, Colors.LabelText))
			tooltip:AddLine(DCL:ColorString(L.MINIMAP_ICON_TOOLTIP_1, DCL.CSS.White))
      tooltip:AddLine(DCL:ColorString(L.MINIMAP_ICON_TOOLTIP_2, DCL.CSS.White))
      tooltip:AddLine(DCL:ColorString(L.MINIMAP_ICON_TOOLTIP_3, DCL.CSS.White))
		end,
  })

  LDBIcon:Register(ObjectName, self.LDB, DejunkDB:GetGlobal("Minimap"))

  self.Initialize = nil
end

-- Displays the minimap icon.
function MinimapIcon:Show()
  DejunkDB:SetGlobal("Minimap.hide", false)
  LDBIcon:Show(ObjectName)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  DejunkDB:SetGlobal("Minimap.hide", true)
  LDBIcon:Hide(ObjectName)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if DejunkDB:GetGlobal("Minimap.hide") then
    self:Show()
  else
    self:Hide()
  end
end
