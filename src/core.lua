-- Core: initializes Dejunk.

local AddonName, Addon = ...
local Colors = Addon.Colors
local Confirmer = Addon.Confirmer
local Consts = Addon.Consts
local Core = Addon.Core
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local GetNetStats = _G.GetNetStats
local L = Addon.Libs.L
local ListManager = Addon.ListManager
local max = math.max
local MerchantButton = Addon.MerchantButton
local MinimapIcon = Addon.MinimapIcon
local print = print
local Repairer = Addon.Repairer
local select = select
local Tools = Addon.Tools
local UI = Addon.UI

-- ============================================================================
-- DethsAddonLib Functions
-- ============================================================================

-- Initializes modules.
function Core:OnInitialize()
  DB:Initialize()
  ListManager:Initialize()
  Consts:Initialize()
  MerchantButton:Initialize()
  MinimapIcon:Initialize()

  -- Setup slash command
  _G.DethsLibLoader("DethsCmdLib", "1.0"):Create(
    AddonName,
    function() UI:Toggle() end,
    "dj"
  )
end

do -- OnUpdate()
  local DELAY = 10 -- seconds
  local interval = DELAY
  local home, world, latency

  function Core:OnUpdate(elapsed)
    UI:OnUpdate(elapsed)

    interval = interval + elapsed
    if (interval >= DELAY) then -- Update latency
      interval = 0
      home, world = select(3, GetNetStats())
      latency = max(home, world) * 0.001 -- convert to seconds
      self.MinDelay = max(latency, 0.1) -- 0.1 seconds min
    end

    ListManager:OnUpdate(elapsed)
    if Dejunker.OnUpdate then Dejunker:OnUpdate(elapsed) end
    if Destroyer.OnUpdate then Destroyer:OnUpdate(elapsed) end
    if Repairer.OnUpdate then Repairer:OnUpdate(elapsed) end
    Confirmer:OnUpdate(elapsed)
  end
end

function Core:OnEvent(event, ...)
  Dejunker:OnEvent(event, ...)
  Repairer:OnEvent(event, ...)
end
Core:RegisterEvent("MERCHANT_SHOW")
Core:RegisterEvent("MERCHANT_CLOSED")
Core:RegisterEvent("UI_ERROR_MESSAGE")

-- ============================================================================
-- General Functions
-- ============================================================================

-- Prints a formatted message ("[Dejunk] msg").
-- @param ... - the messages to print
function Core:Print(...)
  if DB.Profile.SilentMode then return end
  print(DCL:ColorString(("[%s]"):format(AddonName), Colors.Primary), ...)
end

-- Attempts to print a message if verbose mode is enabled.
-- @param ... - the messages to print
function Core:PrintVerbose(...)
  if DB.Profile.VerboseMode then self:Print(...) end
end

--[[
-- Prints a debug message ("[Dejunk Debug] title: ...").
-- @param title - the title of the debug message
-- @param ... - the messages to print
function Core:Debug(title, ...)
  print(
    DCL:ColorString(("[%s Debug]"):format(AddonName), Colors.Red),
    (select("#", ...) > 0) and
    DCL:ColorString(title, Colors.Green)..":" or
    title,
    ...
  )
end
--]] Core.Debug = _G.nop

-- Returns true if the dejunking process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDejunk()
  if Dejunker:IsBusy() then
    return false, L.DEJUNKING_IN_PROGRESS
  end

  if Destroyer:IsBusy() then
    return false, L.CANNOT_DEJUNK_WHILE_DESTROYING
  end

  if ListManager:IsParsing("Inclusions") or ListManager:IsParsing("Exclusions") then
    return
      false,
      L.CANNOT_DEJUNK_WHILE_LISTS_UPDATING:format(
        Tools:GetColoredListName("Inclusions"),
        Tools:GetColoredListName("Exclusions")
      )
  end

  return true
end

-- Returns true if the destroying process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDestroy()
  if Destroyer:IsBusy() then
    return false, L.DESTROYING_IN_PROGRESS
  end

  if Dejunker:IsBusy() then
    return false, L.CANNOT_DESTROY_WHILE_DEJUNKING
  end

  if ListManager:IsParsing("Destroyables") then
    return
      false,
      L.CANNOT_DESTROY_WHILE_LIST_UPDATING:format(
        Tools:GetColoredListName("Destroyables")
      )
  end

  return true
end

-- Returns true if Dejunk is busy performing a critical action.
-- @return - boolean
function Core:IsBusy()
  return
    Dejunker:IsDejunking() or
    Destroyer:IsDestroying() or
    ListManager:IsParsing() or
    Confirmer:IsConfirming()
end
