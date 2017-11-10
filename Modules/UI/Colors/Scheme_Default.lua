local AddonName, DJ = ...
local Colors = DJ.Colors

local schemeName = LibStub('AceLocale-3.0'):GetLocale(AddonName).SCHEME_NAME_DEFAULT

Colors.SchemeNames[#Colors.SchemeNames+1] = schemeName
Colors.Schemes[schemeName] = function()
  return Colors.DefaultColors
end
