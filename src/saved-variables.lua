local _, Addon = ...
local SavedVariables = Addon.SavedVariables
local EventManager = Addon.EventManager
local E = Addon.Events

local GLOBAL_SV = "__DEJUNK_ADDON_GLOBAL_SAVED_VARIABLES__"
local PERCHAR_SV = "__DEJUNK_ADDON_PERCHAR_SAVED_VARIABLES__"

local function globalDefaults()
  return {
    -- User interface.
    chatMessages = true,
    itemTooltips = true,
    merchantButton = true,
    minimapIcon = { hide = false },

    -- Junk.
    autoSell = false,
    autoRepair = false,
    safeMode = false,
    includePoorItems = true,
    inclusions = { --[[ ["itemId"] = true, ... ]] },
    exclusions = { --[[ ["itemId"] = true, ... ]] },
  }
end

local function perCharDefaults()
  local t = globalDefaults()
  t.characterSpecificSettings = false
  return t
end

EventManager:Once(E.Wow.PlayerLogin, function()
  if not _G[GLOBAL_SV] then _G[GLOBAL_SV] = globalDefaults() end
  if not _G[PERCHAR_SV] then _G[PERCHAR_SV] = perCharDefaults() end
  local global = _G[GLOBAL_SV]
  local perChar = _G[PERCHAR_SV]

  function SavedVariables:Get()
    return perChar.characterSpecificSettings and perChar or global
  end

  function SavedVariables:GetGlobal()
    return global
  end

  function SavedVariables:GetPerChar()
    return perChar
  end

  function SavedVariables:IsGlobal()
    return perChar.characterSpecificSettings
  end

  function SavedVariables:Switch()
    perChar.characterSpecificSettings = not perChar.characterSpecificSettings
    EventManager:Fire(E.SavedVariablesSwitched)
  end

  EventManager:Fire(E.SavedVariablesReady)
  EventManager:Fire(E.SavedVariablesSwitched)
end)
