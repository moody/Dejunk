-- https://github.com/moody/DethsColorLib-1.0

local MAJOR, MINOR = "DethsColorLib-1.0", 1

-- LibStub
local DCL, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not DCL then return end

-- Lua upvalues
local setmetatable, rawset, pairs = setmetatable, rawset, pairs
local assert, type = assert, type
local format, upper = format, string.upper
local tonumber, floor, random = tonumber, math.floor, math.random

-- WoW upvalues
local Clamp = Clamp

-- Rounds a specified number to a specified number of decimal places.
-- @param n - the number to round
-- @param p - the number of decimal places
local function round(n, p)
  p = p and (10 ^ p) or 1
  return floor((n * p) + 0.5) / p
end

-- ============================================================================
-- Color Helper Functions
-- ============================================================================

-- Formats and returns a string with the specified color.
-- @param s - the string to color
-- @param color - color table: {r, g, b[, a]}, or a hex color string: "RRGGBB[AA]"
function DCL:ColorString(s, color)
  if (type(color) == "table") then
    local r, g, b = unpack(color)

    -- Convert to value between 0-255
    r = (Clamp(r, 0, 1) * 255)
    g = (Clamp(g, 0, 1) * 255)
    b = (Clamp(b, 0, 1) * 255)

    -- Color format (hex): AARRGGBB
    -- %02X = two-digit hex value, 00-FF
    return format("|cFF%02X%02X%02X%s|r", r, g, b, s)
  else -- Hex
    if (#color == 8) then color = color:match("%x%x%x%x%x%x") end
    return format("|cFF%s%s|r", color, s)
  end
end

do -- RainbowString()
  local rainbow = {
    "9B59B6", -- Violet
    "8E44AD", -- Indigo
    "3498DB", -- Blue
    "2ECC71", -- Green
    "F1C40F", -- Yellow
    "E67E22", -- Orange
    "E74C3C", -- Red
  }
  
  -- Formats and returns a string with rainbow colors.
  -- @param s - the string to color
  function DCL:RainbowString(s)
    local rbs = {} -- rainbow string
    local i = 1 -- rainbow index
    
    -- Loop & color each character
    for c in s:gmatch(".") do
      if not (c == " ") then
        c = self:ColorString(c, rainbow[i])
        i = i + 1
        if (i > #rainbow) then i = 1 end
      end
      rbs[#rbs+1] = c
    end

    return table.concat(rbs)
  end
end

-- Removes WoW color escape sequences from a string.
-- @param s - the string to remove color from
-- @return - the original string without color escape sequences
function DCL:RemoveColor(s)
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  return s
end

-- Returns the first color found in the specified string, or "FFFFFF" if no
-- color sequence is found.
-- @oaram s - the string to get a color from
-- @return - a hex color string: "RRGGBB"
function DCL:GetStringColor(s)
  s = s:match("|c%x%x%x%x%x%x%x%x")
  s = s and s:gsub("|c%x%x", "") or "FFFFFF"
  return s
end

-- Returns a randomized color with full alpha.
-- @return - color table: {r, g, b, a}
function DCL:GetRandomColor()
  return {random(), random(), random(), 1}
end

do -- DCL:HexToRGBA()
  local RGBA_TO_PERCENT = (1 / 255)
  local HEX_TO_RGBA = {}

  -- Returns a table with red, green, blue, and alpha values.
  -- Example: "FFFFFF" returns {1, 1, 1, 1}
  -- @param hex - a hex color string: "RRGGBB[AA]"
  -- @return - color table: {r, g, b, a}
  function DCL:HexToRGBA(hex)
    assert(type(hex) == "string", "hex value must be a string")
    assert((#hex == 6) or (#hex == 8), "hex value must have a length of 6 or 8: "..hex)
    
    -- Add max alpha if not supplied in hex
    if (#hex == 6) then hex = hex.."FF" end
    hex = upper(hex)

    -- Return cached color if it exists
    if HEX_TO_RGBA[hex] then return HEX_TO_RGBA[hex] end
    
    -- Otherwise, convert, cache, and return
    assert(tonumber(hex, 16), "invalid hex value: "..hex)
    local rgba = {}
    for h in hex:gmatch("%x%x") do
      -- Convert hex to base 10 percentage of 255, rounded to 2 decimal places
      rgba[#rgba+1] = round(tonumber(h, 16) * RGBA_TO_PERCENT, 2)
    end

    HEX_TO_RGBA[hex] = rgba
    return rgba
  end
end

-- Converts hex values in a table to rgba tables.
-- @param t - a table with key value pairs (e.g. t = { White = "FFFFFF" })
function DCL:HexTableToRGBA(t)
  for k, v in pairs(t) do t[k] = self:HexToRGBA(v) end
end

-- ============================================================================
-- Color Table Functions
-- ============================================================================

do
  local COLOR_TABLES = {}

  -- Returns a color table previously created by a call to DCL:NewColorTable()
  -- @param name - the unique name of the color table to get
  function DCL:GetColorTable(name)
    assert(COLOR_TABLES[name],
      format("color table for \"%s\" does not exist", name))
    return COLOR_TABLES[name]
  end

  -- Creates and returns a new color table with default colors.
  -- @param name - a unique name for the table
  -- @param defaultColors - table: { ColorName = "RRGGBB[AA]", ... }
  function DCL:NewColorTable(name, defaultColors)
    assert(type(name) == "string", "name must be a string")
    assert(not COLOR_TABLES[name], format("\"%s\" already exists", name))
    assert(type(defaultColors) == "table", "defaultColors must be a table")

    -- Initialize a new color table
    local colorTable = {
      SetColors = function(t, colors)
        -- Update color tables
        for k, hex in pairs(colors) do
          if not defaultColors[k] then error(k.." is not a default color key") end
          for i, rgba in ipairs(DCL:HexToRGBA(hex)) do t[k][i] = rgba end
        end
        -- Reset missing keys to default
        for k, hex in pairs(defaultColors) do
          if not colors[k] then
            for i, rgba in ipairs(DCL:HexToRGBA(hex)) do t[k][i] = rgba end
          end
        end
      end
    }

    -- Initialize color key tables and colors
    for k, hex in pairs(defaultColors) do colorTable[k] = {} end
    colorTable:SetColors(defaultColors)

    -- Lock so table/function references cannot be changed
    colorTable = setmetatable({}, {
      __index = colorTable,
      __newindex = function()
        error("color tables are read-only")
      end
    })

    -- Store and return
    COLOR_TABLES[name] = colorTable
    return colorTable
  end
end

-- ============================================================================
-- Wow Colors, and DCL:GetColorByQuality()
-- ============================================================================

DCL.Wow = {
  Poor = "9D9D9D",
  Common = "FFFFFF",
  Uncommon = "1EFF00",
  Rare = "0070DD",
  Epic = "A335EE",
  Legendary = "FF8000",
  Artifact = "E6CC80",
  Heirloom = "00CCFF",
  WowToken = "00CCFF"
}
DCL:HexTableToRGBA(DCL.Wow)

do -- GetColorByQuality()
  local colorByQuality = {
    [LE_ITEM_QUALITY_POOR] = DCL.Wow.Poor,
    [LE_ITEM_QUALITY_COMMON] = DCL.Wow.Common,
    [LE_ITEM_QUALITY_UNCOMMON] = DCL.Wow.Uncommon,
    [LE_ITEM_QUALITY_RARE] = DCL.Wow.Rare,
    [LE_ITEM_QUALITY_EPIC] = DCL.Wow.Epic,
    [LE_ITEM_QUALITY_LEGENDARY] = DCL.Wow.Legendary,
    [LE_ITEM_QUALITY_ARTIFACT] = DCL.Wow.Artifact,
    [LE_ITEM_QUALITY_HEIRLOOM] = DCL.Wow.Heirloom,
    [LE_ITEM_QUALITY_WOW_TOKEN] = DCL.Wow.WowToken
  }
  
  -- Returns a color table specified by item quality.
  -- @param quality - a numeric value between LE_ITEM_QUALITY_POOR and LE_ITEM_QUALITY_WOW_TOKEN
  function DCL:GetColorByQuality(quality)
    return colorByQuality[quality] or error("invalid item quality: "..tostring(quality))
  end
end

-- ============================================================================
-- CSS Colors - https://www.w3schools.com/colors/colors_names.asp
-- ============================================================================

DCL.CSS = {
  AliceBlue = "F0F8FF",
  AntiqueWhite = "FAEBD7",
  Aqua = "00FFFF",
  Aquamarine = "7FFFD4",
  Azure = "F0FFFF",
  Beige = "F5F5DC",
  Bisque = "FFE4C4",
  Black = "000000",
  BlanchedAlmond = "FFEBCD",
  Blue = "0000FF",
  BlueViolet = "8A2BE2",
  Brown = "A52A2A",
  BurlyWood = "DEB887",
  CadetBlue = "5F9EA0",
  Chartreuse = "7FFF00",
  Chocolate = "D2691E",
  Coral = "FF7F50",
  CornflowerBlue = "6495ED",
  Cornsilk = "FFF8DC",
  Crimson = "DC143C",
  Cyan = "00FFFF",
  DarkBlue = "00008B",
  DarkCyan = "008B8B",
  DarkGoldenRod = "B8860B",
  DarkGray = "A9A9A9",
  DarkGrey = "A9A9A9",
  DarkGreen = "006400",
  DarkKhaki = "BDB76B",
  DarkMagenta = "8B008B",
  DarkOliveGreen = "556B2F",
  DarkOrange = "FF8C00",
  DarkOrchid = "9932CC",
  DarkRed = "8B0000",
  DarkSalmon = "E9967A",
  DarkSeaGreen = "8FBC8F",
  DarkSlateBlue = "483D8B",
  DarkSlateGray = "2F4F4F",
  DarkSlateGrey = "2F4F4F",
  DarkTurquoise = "00CED1",
  DarkViolet = "9400D3",
  DeepPink = "FF1493",
  DeepSkyBlue = "00BFFF",
  DimGray = "696969",
  DimGrey = "696969",
  DodgerBlue = "1E90FF",
  FireBrick = "B22222",
  FloralWhite = "FFFAF0",
  ForestGreen = "228B22",
  Fuchsia = "FF00FF",
  Gainsboro = "DCDCDC",
  GhostWhite = "F8F8FF",
  Gold = "FFD700",
  GoldenRod = "DAA520",
  Gray = "808080",
  Grey = "808080",
  Green = "008000",
  GreenYellow = "ADFF2F",
  HoneyDew = "F0FFF0",
  HotPink = "FF69B4",
  IndianRed = "CD5C5C",
  Indigo = "4B0082",
  Ivory = "FFFFF0",
  Khaki = "F0E68C",
  Lavender = "E6E6FA",
  LavenderBlush = "FFF0F5",
  LawnGreen = "7CFC00",
  LemonChiffon = "FFFACD",
  LightBlue = "ADD8E6",
  LightCoral = "F08080",
  LightCyan = "E0FFFF",
  LightGoldenRodYellow = "FAFAD2",
  LightGray = "D3D3D3",
  LightGrey = "D3D3D3",
  LightGreen = "90EE90",
  LightPink = "FFB6C1",
  LightSalmon = "FFA07A",
  LightSeaGreen = "20B2AA",
  LightSkyBlue = "87CEFA",
  LightSlateGray = "778899",
  LightSlateGrey = "778899",
  LightSteelBlue = "B0C4DE",
  LightYellow = "FFFFE0",
  Lime = "00FF00",
  LimeGreen = "32CD32",
  Linen = "FAF0E6",
  Magenta = "FF00FF",
  Maroon = "800000",
  MediumAquaMarine = "66CDAA",
  MediumBlue = "0000CD",
  MediumOrchid = "BA55D3",
  MediumPurple = "9370DB",
  MediumSeaGreen = "3CB371",
  MediumSlateBlue = "7B68EE",
  MediumSpringGreen = "00FA9A",
  MediumTurquoise = "48D1CC",
  MediumVioletRed = "C71585",
  MidnightBlue = "191970",
  MintCream = "F5FFFA",
  MistyRose = "FFE4E1",
  Moccasin = "FFE4B5",
  NavajoWhite = "FFDEAD",
  Navy = "000080",
  OldLace = "FDF5E6",
  Olive = "808000",
  OliveDrab = "6B8E23",
  Orange = "FFA500",
  OrangeRed = "FF4500",
  Orchid = "DA70D6",
  PaleGoldenRod = "EEE8AA",
  PaleGreen = "98FB98",
  PaleTurquoise = "AFEEEE",
  PaleVioletRed = "DB7093",
  PapayaWhip = "FFEFD5",
  PeachPuff = "FFDAB9",
  Peru = "CD853F",
  Pink = "FFC0CB",
  Plum = "DDA0DD",
  PowderBlue = "B0E0E6",
  Purple = "800080",
  RebeccaPurple = "663399",
  Red = "FF0000",
  RosyBrown = "BC8F8F",
  RoyalBlue = "4169E1",
  SaddleBrown = "8B4513",
  Salmon = "FA8072",
  SandyBrown = "F4A460",
  SeaGreen = "2E8B57",
  SeaShell = "FFF5EE",
  Sienna = "A0522D",
  Silver = "C0C0C0",
  SkyBlue = "87CEEB",
  SlateBlue = "6A5ACD",
  SlateGray = "708090",
  SlateGrey = "708090",
  Snow = "FFFAFA",
  SpringGreen = "00FF7F",
  SteelBlue = "4682B4",
  Tan = "D2B48C",
  Teal = "008080",
  Thistle = "D8BFD8",
  Tomato = "FF6347",
  Turquoise = "40E0D0",
  Violet = "EE82EE",
  Wheat = "F5DEB3",
  White = "FFFFFF",
  WhiteSmoke = "F5F5F5",
  Yellow = "FFFF00",
  YellowGreen = "9ACD32",
}
DCL:HexTableToRGBA(DCL.CSS)
