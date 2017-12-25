-- Dejunk_MinimapIcon: provides a minimap button for Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

-- Dejunk
local MinimapIcon = DJ.MinimapIcon

local Colors = DJ.Colors
local Tools = DJ.Tools

-- Variables
MinimapIcon.Initialized = false

local ObjectName = "DejunkMinimapIcon"

-- ============================================================================
--                             Minimap Button
-- ============================================================================

-- Initializes the minimap icon.
function MinimapIcon:Initialize()
  if self.Initialized then return end

  self.LDB = LDB:NewDataObject(ObjectName, {
  	icon = "Interface\\AddOns\\Dejunk\\Dejunk_Icon",

    OnClick = function(_, button)
      if (button == "LeftButton") then
        DJ.Core:ToggleGUI()
      elseif (button == "RightButton") then
        DJ.Destroyer:StartDestroying()
      end
    end,

    OnTooltipShow = function(tooltip)
			tooltip:AddLine(Tools:GetColorString(AddonName, Colors.LabelText))
			tooltip:AddLine(Tools:GetColorString(L.MINIMAP_ICON_TOOLTIP_1, Colors.White))
      tooltip:AddLine(Tools:GetColorString(L.MINIMAP_ICON_TOOLTIP_2, Colors.White))
      tooltip:AddLine(Tools:GetColorString(L.MINIMAP_ICON_TOOLTIP_3, Colors.White))
		end,
  })

  if DejunkGlobal.Minimap == nil then
    DejunkGlobal.Minimap = { hide = false }
  end

  LDBIcon:Register(ObjectName, self.LDB, DejunkGlobal.Minimap)

  self.Initialized = true
end

-- Displays the minimap icon.
function MinimapIcon:Show()
  DejunkGlobal.Minimap.hide = false
  LDBIcon:Show(ObjectName)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  DejunkGlobal.Minimap.hide = true
  LDBIcon:Hide(ObjectName)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if DejunkGlobal.Minimap.hide then
    self:Show()
  else
    self:Hide()
  end
end
