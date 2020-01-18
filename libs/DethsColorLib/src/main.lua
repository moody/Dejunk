-- https://github.com/moody/DethsColorLib

local _, Addon = ...
local DCL = Addon.DethsColorLib
if DCL.__loaded then return end

local assert = assert
local Clamp = _G.Clamp
local error = error
local format = string.format
local ipairs = ipairs
local pairs = pairs
local random = _G.random
local setmetatable = setmetatable
local strupper = _G.strupper
local tconcat = table.concat
local tonumber = tonumber
local type = type
local unpack = _G.unpack

-- ============================================================================
-- Color Helper Functions
-- ============================================================================

-- Formats and returns a string with the specified color.
-- @param s - the string to color
-- @param color - rgba table: {r, g, b[, a]}, or a hex color string: "RRGGBB[AA]"
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

  local buffer = {}

  -- Formats and returns a string with rainbow colors.
  -- @param s - the string to color
  function DCL:RainbowString(s)
    for k in pairs(buffer) do buffer[k] = nil end
    local i = 1 -- rainbow index

    -- Loop & color each character
    for c in s:gmatch(".") do
      if not (c == " ") then
        c = self:ColorString(c, rainbow[i])
        i = i + 1
        if (i > #rainbow) then i = 1 end
      end
      buffer[#buffer+1] = c
    end

    return tconcat(buffer)
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
-- @param s - the string to get a color from
-- @return - a hex color string: "RRGGBB"
function DCL:GetStringColor(s)
  s = s:match("|c%x%x%x%x%x%x%x%x")
  s = s and s:gsub("|c%x%x", "") or "FFFFFF"
  return s
end

-- Returns a randomized color with full alpha.
-- @return - rgba table: {r, g, b, a}
function DCL:GetRandomColor()
  return {random(), random(), random(), 1}
end

do -- DCL:HexToRGBA()
  local HEX_TO_RGBA = {}

  -- Returns a table with red, green, blue, and alpha values.
  -- Example: "FFFFFF" returns {1, 1, 1, 1}
  -- @param hex - a hex color string: "RRGGBB[AA]"
  -- @return - rgba table: {r, g, b, a}
  function DCL:HexToRGBA(hex)
    assert(type(hex) == "string", "hex value must be a string")
    assert((#hex == 6) or (#hex == 8), "hex value must have a length of 6 or 8: "..hex)

    -- Add max alpha if not supplied in hex
    if (#hex == 6) then hex = hex.."FF" end
    hex = strupper(hex)

    -- Return cached color if it exists
    if HEX_TO_RGBA[hex] then return HEX_TO_RGBA[hex] end

    -- Otherwise, convert, cache, and return
    assert(tonumber(hex, 16), "invalid hex value: "..hex)
    local rgba = {}
    for h in hex:gmatch("%x%x") do
      -- Convert hex to base 10 percentage of 255
      rgba[#rgba+1] = tonumber(h, 16) / 255
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
    return COLOR_TABLES[name] or error(format("color table for \"%s\" does not exist", name))
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
