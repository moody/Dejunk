local _, Addon = ...
local DDBL = Addon.DethsDBLib
if DDBL.__loaded then return end

local consts  = DDBL.consts

consts.PLAYER_KEY = ("%s-%s"):format(_G.UnitName("PLAYER"), _G.GetRealmName())

consts.TOC_ENTRY = "X-DethsDBLib"
consts.TOC_ERROR_MSG = [=[
%s.toc must contain:

## SavedVariables: my_addon_sv_key
## X-DethsDBLib: my_addon_sv_key

Where "my_addon_sv_key" is a unique global variable name.
]=]

consts.ADDON_NOT_LOADED_MSG = [=[
SavedVariables for "%s" are not available yet.

Wait until the "ADDON_LOADED" event has fired before creating a database.
]=]
