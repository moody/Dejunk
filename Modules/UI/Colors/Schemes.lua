local AddonName, Addon = ...
local Colors = Addon.Colors

local L = Addon.Libs.L

do -- Default
  local schemeName = L.SCHEME_NAME_DEFAULT

  Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
  Colors.Schemes[schemeName] = Colors.DefaultColors
end

do -- Gray
  local schemeName = L.SCHEME_NAME_GRAY

  Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
  Colors.Schemes[schemeName] = {
    ParentFrame = "0D0D0DF2",

    Title = "808080FF",
    TitleShadow = "333333FF",

    Button = "262626FF",
    ButtonHi = "4D4D4DFF",
    ButtonText = "E6E6E6FF",
    ButtonTextHi = "FFFFFFFF",

    LabelText = "999999FF",

    Area = "33333380",

    ScrollFrame = "33333380",
    Slider = "33333380",
    SliderThumb = "333333FF",
    SliderThumbHi = "4D4D4DFF",
    ListButton = "333333FF",
    ListButtonHi = "4D4D4DFF",
  }
end

do -- Green
  local schemeName = L.SCHEME_NAME_GREEN

  Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
  Colors.Schemes[schemeName] = {
    ParentFrame = "000D00F2",

    Title = "3F803FFF",
    TitleShadow = "0D330DFF",

    Button = "0D260DFF",
    ButtonHi = "264D26FF",
    ButtonText = "80FF80FF",
    ButtonTextHi = "FFFFFFFF",

    LabelText = "599959FF",

    Area = "1A331A80",

    ScrollFrame = "1A331A80",
    Slider = "1A331A80",
    SliderThumb = "1A331AFF",
    SliderThumbHi = "264D26FF",
    ListButton = "1A331AFF",
    ListButtonHi = "264D26FF",
  }
end

do -- Purple
  local schemeName = L.SCHEME_NAME_PURPLE

  Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
  Colors.Schemes[schemeName] = {
    ParentFrame = "0D000DF2",

    Title = "803F80FF",
    TitleShadow = "330D33FF",

    Button = "260D26FF",
    ButtonHi = "4D264DFF",
    ButtonText = "FF80FFFF",
    ButtonTextHi = "FFFFFFFF",

    LabelText = "995999FF",

    Area = "331A3380",

    ScrollFrame = "331A3380",
    Slider = "331A3380",
    SliderThumb = "331A33FF",
    SliderThumbHi = "4D264DFF",
    ListButton = "331A33FF",
    ListButtonHi = "4D264DFF",
  }
end

do -- Red
  local schemeName = L.SCHEME_NAME_RED

  Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
  Colors.Schemes[schemeName] = {
    ParentFrame = "0D0000F2",

    Title = "803F3FFF",
    TitleShadow = "330D0DFF",

    Button = "260D0DFF",
    ButtonHi = "4D2626FF",
    ButtonText = "FF8080FF",
    ButtonTextHi = "FFFFFFFF",

    LabelText = "995959FF",

    Area = "331A1A80",

    ScrollFrame = "331A1A80",
    Slider = "331A1A80",
    SliderThumb = "331A1AFF",
    SliderThumbHi = "4D2626FF",
    ListButton = "331A1AFF",
    ListButtonHi = "4D2626FF",
  }
end
