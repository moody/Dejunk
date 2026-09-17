local Addon = select(2, ...) ---@type Addon

--- @class Colors
local Colors = Addon:GetModule("Colors")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Creates a color from the given AARRGGBB hex string.
--- @param hex string AARRGGBB
--- @return Color
local function createColor(hex)
  local color = CreateColorFromHexString(hex)

  --- @class Color
  --- @overload fun(text: string): string
  local wrapper = setmetatable({}, {
    __call = function(self, text, alpha)
      alpha = (alpha or 1) * 255
      local _hex = ("%.2x%.2x%.2x%.2x"):format(alpha, color:GetRGBAsBytes())
      return WrapTextInColorCode(text or "", _hex)
    end
  })

  --- Returns the color's normalized RGB values.
  --- @return number r, number g, number b
  function wrapper:GetRGB()
    return color:GetRGB()
  end

  --- Returns the color's normalized RGBA values.
  --- @param alpha? number normalized alpha (optional override)
  --- @return number r, number g, number b, number? a
  function wrapper:GetRGBA(alpha)
    local r, g, b, a = color:GetRGBA()
    return r, g, b, alpha or a
  end

  --- Returns the color as an AARRGGBB hex string.
  --- @param alpha number normalized alpha
  --- @return string hex
  function wrapper:GetHex(alpha)
    alpha = (alpha or 1) * 255
    return ("%.2x%.2x%.2x%.2x"):format(alpha, color:GetRGBAsBytes())
  end

  --- @cast wrapper Color
  return wrapper
end

-- =============================================================================
-- Colors
-- =============================================================================

Colors.Backdrop = createColor("FF121212")
Colors.Black = createColor("FF000000")
Colors.Blue = createColor("FF4FAFE3")
Colors.DarkGrey = createColor("FF1E1E1E")
Colors.Gold = createColor("FFFFD100")
Colors.Green = createColor("FF4FE34F")
Colors.Grey = createColor("FF9D9D9D")
Colors.Pink = createColor("FFDD75DD")
Colors.QualityCommon = createColor("FFFFFFFF")
Colors.QualityEpic = createColor("FFA335EE")
Colors.QualityPoor = createColor("FF9D9D9D")
Colors.QualityRare = createColor("FF0070DD")
Colors.QualityUncommon = createColor("FF1EFF00")
Colors.Red = createColor("FFE34F4F")
Colors.White = createColor("FFFFFFFF")
Colors.Yellow = createColor("FFE3E34F")
