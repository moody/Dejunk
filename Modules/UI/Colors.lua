-- Colors: provides Dejunk modules easy access to various colors.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL

-- Modules
local Colors = Addon.Colors
Colors.Schemes = {}

local DB = Addon.DB
local ParentFrame = Addon.Frames.ParentFrame

-- Variables
local currentIndex

-- ============================================================================
-- General Functions
-- ============================================================================

-- Initializes the Colors table.
function Colors:Initialize()
  local index = tonumber(DB.Global.ColorScheme) or 1
  self:SetColorScheme(index)
  self.Initialize = nil
end

-- Sets the current color scheme by index.
-- @param index - the index of a color scheme in Colors.Schemes
function Colors:SetColorScheme(index)
  if not self.Schemes[index] then index = 1 end
  
  DB.Global.ColorScheme = index
  self.ColorTable:SetColors(self.Schemes[index])
  currentIndex = index

  if ParentFrame.Frame then ParentFrame:Refresh() end
end

-- Switches to the next color scheme.
function Colors:NextScheme()
  local nextIndex = currentIndex + 1
  if not self.Schemes[nextIndex] then nextIndex = 1 end
  self:SetColorScheme(nextIndex)
end

-- ============================================================================
-- DCL ColorTable
-- ============================================================================

local defaultColors = {
  -- General
  None = "00000000",
  Red = "CC3F3FFF",
  Green = "3FCC3FFF",
  Blue = "3F3FCCFF",
  Yellow = "CCCC3FFF",

  -- Lists
  Inclusions = "CC3F3FFF",
  InclusionsHi = "E66666FF",

  Exclusions = "3FCC3FFF",
  ExclusionsHi = "66E666FF",

  Destroyables = "CCCC3FFF",
  DestroyablesHi = "E6E666FF",

  -- GUI
  ParentFrame = "0D0D0DF2",
  Border = "333333",
  
  Title = "808080FF",
  TitleShadow = "333333FF",
  
  Button = "262626FF",
  ButtonHi = "4D4D4DFF",
  ButtonText = "E6E6E6FF",
  ButtonTextHi = "FFFFFFFF",
  
  LabelText = "999999FF",
  
  ScrollFrame = "33333380",
  Slider = "33333380",
  SliderThumb = "333333FF",
  SliderThumbHi = "4D4D4DFF",
  ListButton = "333333FF",
  ListButtonHi = "4D4D4DFF",
}

-- Create a DCL color table and set it as the metatable index for Colors
-- The metatable allows us to easily reference colors (e.g. Colors.Button)
Colors.ColorTable = DCL:NewColorTable(AddonName, defaultColors)
-- for k in pairs(Colors.ColorTable) do assert(Colors[k] == nil) end
setmetatable(Colors, {__index = Colors.ColorTable})

-- For objects with a slider, this helps make SetColors() less verbose
Colors.SliderColors = {
  Colors.Slider,
  Colors.SliderThumb,
  Colors.SliderThumbHi
}

-- ============================================================================
-- Schemes
-- ============================================================================

-- Default (Gray)
Colors.Schemes[#Colors.Schemes+1] = defaultColors

-- Red
Colors.Schemes[#Colors.Schemes+1] = {
  ParentFrame = "0D0000F2",
  Border = "331A1A",

  Title = "803F3FFF",
  TitleShadow = "330D0DFF",

  Button = "260D0DFF",
  ButtonHi = "4D2626FF",
  ButtonText = "FF8080FF",
  ButtonTextHi = "FFFFFFFF",

  LabelText = "995959FF",

  ScrollFrame = "331A1A80",
  Slider = "331A1A80",
  SliderThumb = "331A1AFF",
  SliderThumbHi = "4D2626FF",
  ListButton = "331A1AFF",
  ListButtonHi = "4D2626FF",
}

-- Green
Colors.Schemes[#Colors.Schemes+1] = {
  ParentFrame = "000D00F2",
  Border = "1A331A",

  Title = "3F803FFF",
  TitleShadow = "0D330DFF",

  Button = "0D260DFF",
  ButtonHi = "264D26FF",
  ButtonText = "80FF80FF",
  ButtonTextHi = "FFFFFFFF",

  LabelText = "599959FF",

  ScrollFrame = "1A331A80",
  Slider = "1A331A80",
  SliderThumb = "1A331AFF",
  SliderThumbHi = "264D26FF",
  ListButton = "1A331AFF",
  ListButtonHi = "264D26FF",
}

-- Blue
Colors.Schemes[#Colors.Schemes+1] = {
  ParentFrame = "00000DF2",
  Border = "1A1A33",

  Title = "3F3F80FF",
  TitleShadow = "0D0D33FF",

  Button = "0D0D26FF",
  ButtonHi = "26264DFF",
  ButtonText = "8080FFFF",
  ButtonTextHi = "FFFFFFFF",

  LabelText = "595999FF",

  ScrollFrame = "1A1A3380",
  Slider = "1A1A3380",
  SliderThumb = "1A1A33FF",
  SliderThumbHi = "26264DFF",
  ListButton = "1A1A33FF",
  ListButtonHi = "26264DFF",
}

-- Purple
Colors.Schemes[#Colors.Schemes+1] = {
  ParentFrame = "0D000DF2",
  Border = "331A33",

  Title = "803F80FF",
  TitleShadow = "330D33FF",

  Button = "260D26FF",
  ButtonHi = "4D264DFF",
  ButtonText = "FF80FFFF",
  ButtonTextHi = "FFFFFFFF",

  LabelText = "995999FF",

  ScrollFrame = "331A3380",
  Slider = "331A3380",
  SliderThumb = "331A33FF",
  SliderThumbHi = "4D264DFF",
  ListButton = "331A33FF",
  ListButtonHi = "4D264DFF",
}
