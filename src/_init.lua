local ADDON_NAME, Addon = ...

Addon.VERSION = GetAddOnMetadata(ADDON_NAME, "Version")
Addon.IS_RETAIL = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

-- ============================================================================
-- Tables
-- ============================================================================

-- Libs.
Addon.Libs = {
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0")
}

-- Locale.
Addon.Locale = setmetatable({}, {
  __index = function(t, k)
    return rawget(t, k) or k
  end
})

do -- Colors.
  Addon.Colors = {}

  local colors = {
    White = "FFFFFFFF",
    Blue = "FF4FAFE3",
    Red = "FFE34F4F",
    Green = "FF4FE34F",
    Yellow = "FFE3E34F",
    Gold = "FFFFD100",
    Grey = "FF9D9D9D",
    DarkGrey = "FF1E1E1E"
  }

  for name, hex in pairs(colors) do
    local color = CreateColorFromHexString(hex)

    local t = setmetatable({}, {
      __call = function(self, text, alpha)
        alpha = (alpha or 1) * 255
        local _hex = ("%.2x%.2x%.2x%.2x"):format(alpha, color:GetRGBAsBytes())
        return WrapTextInColorCode(text or "", _hex)
      end
    })

    function t:GetRGB()
      return color:GetRGB()
    end

    function t:GetRGBA(alpha)
      local r, g, b, a = color:GetRGBA()
      return r, g, b, alpha or a
    end

    function t:GetHex(alpha)
      alpha = (alpha or 1) * 255
      return ("%.2x%.2x%.2x%.2x"):format(alpha, color:GetRGBAsBytes())
    end

    Addon.Colors[name] = t
  end
end

-- Events.
Addon.Events = {}
Addon.EventManager = {}

-- SavedVariables.
Addon.SavedVariables = {}

-- Commands.
Addon.Commands = {}

-- Bags.
Addon.Bags = {}

-- Lists.
Addon.Lists = {
  Inclusions = {},
  Exclusions = {}
}

-- JunkFilter.
Addon.JunkFilter = {}

-- Seller.
Addon.Seller = {}

-- Destroyer.
Addon.Destroyer = {}

-- UserInterface.
Addon.UserInterface = {
  JunkFrame = {},
  Widgets = {}
}

-- ============================================================================
-- Functions
-- ============================================================================

function Addon:IsBusy()
  if self.Seller:IsBusy() then return true, self.Locale.IS_BUSY_SELLING_ITEMS end
  if self.Lists:IsBusy() then return true, self.Locale.IS_BUSY_UPDATING_LISTS end
  return false
end

function Addon:ForcePrint(...)
  print(self.Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
end

function Addon:Print(...)
  if self.SavedVariables:Get().chatMessages then
    print(self.Colors.Blue("[" .. ADDON_NAME .. "]"), ...)
  end
end

function Addon:Debug(...)
  print(self.Colors.Red("[Debug]"), ...)
end
