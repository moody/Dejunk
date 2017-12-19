-- Bindings: sets up binding data and functions.

local AddonName, DJ = ...
local _G = _G

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Destroyer = DJ.Destroyer

-- Text
_G["BINDING_HEADER_DEJUNKHEADER"] = AddonName
_G["BINDING_NAME_DEJUNKSTARTDESTROY"] = L.START_DESTROYING_BUTTON_TEXT

-- ============================================================================
--                              Bindings Functions
-- ============================================================================

function DejunkBindings_StartDestroying()
  Destroyer:StartDestroying()
end
