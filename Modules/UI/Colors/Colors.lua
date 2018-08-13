-- Colors: provides Dejunk modules easy access to various colors.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL

-- Modules
local Colors = Addon.Colors

local DB = Addon.DB
local ParentFrame = Addon.Frames.ParentFrame

-- Variables
Colors.Schemes = {}
Colors.SchemeNames = {}
Colors.CurrentSchemeName = nil

-- ============================================================================
-- General Functions
-- ============================================================================

-- Initializes the Colors table.
function Colors:Initialize()
  local colorScheme = DB.Global.ColorScheme
  if (colorScheme == nil) or (self.Schemes[colorScheme] == nil) then
    colorScheme = self.SchemeNames[1]
  end

  self:SetColorScheme(colorScheme)

  self.Initialize = nil
end

-- Switches to the next scheme in SchemeNames.
function Colors:NextScheme()
  for i, v in ipairs(self.SchemeNames) do
    if (v == Colors.CurrentSchemeName) then
      i = ((i + 1) % (#self.SchemeNames + 1))
      if (i == 0) then i = 1 end

      self:SetColorScheme(self.SchemeNames[i])
      Addon.Core:Print(format(L.COLOR_SCHEME_SET_TEXT, self.SchemeNames[i]))
      return
    end
  end
end

-- Sets the current color scheme.
-- @param colorScheme - a colorScheme defined in Colors.Schemes
function Colors:SetColorScheme(colorScheme)
  assert(type(colorScheme) == "string", "colorScheme must exist and be a string")
  if not self.Schemes[colorScheme] then colorScheme = self.SchemeNames[1] end

  DB.Global.ColorScheme = colorScheme
  self.ColorTable:SetColors(self.Schemes[colorScheme])
  self.CurrentSchemeName = colorScheme

  if ParentFrame.Frame then ParentFrame:Refresh() end
end

-- ============================================================================
-- DefaultColors / ColorTable
-- ============================================================================

-- Default Dejunk colors
Colors.DefaultColors = {
  -- General
  None = "00000000",
  Red = "CC3F3FFF",
  Green = "3FCC3FFF",
  Blue = "3F3FCCFF",
  Yellow = "CCCC3FFF",

  -- GUI
  ParentFrame = "00000DF2",
  Border = "1A1A33",

  Title = "3F3F80FF",
  TitleShadow = "0D0D33FF",

  Button = "0D0D26FF",
  ButtonHi = "26264DFF",
  ButtonText = "8080FFFF",
  ButtonTextHi = "FFFFFFFF",

  LabelText = "595999FF",

  Inclusions = "CC3F3FFF",
  InclusionsHi = "E66666FF",

  Exclusions = "3FCC3FFF",
  ExclusionsHi = "66E666FF",

  Destroyables = "CCCC3FFF",
  DestroyablesHi = "E6E666FF",

  ScrollFrame = "1A1A3380",
  Slider = "1A1A3380",
  SliderThumb = "1A1A33FF",
  SliderThumbHi = "26264DFF",
  ListButton = "1A1A33FF",
  ListButtonHi = "26264DFF",
}

-- Initialize color table with defaults
Colors.ColorTable = DCL:NewColorTable(AddonName, Colors.DefaultColors)

-- Here we add the color table colors to Colors.
-- This allows us to easily get a color: Colors.Button for example.
for k, v in pairs(Colors.DefaultColors) do
  if Colors[k] then error("Key already exists in Colors: "..k) end
  Colors[k] = Colors.ColorTable[k]
end

-- For objects with a slider, this helps make SetColors() less verbose
Colors.SliderColors = {
  Colors.Slider,
  Colors.SliderThumb,
  Colors.SliderThumbHi
}
