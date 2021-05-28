local _, Addon = ...
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local GetNetStats = _G.GetNetStats
local L = Addon.Libs.L
local ListHelper = Addon.ListHelper
local Lists = Addon.Lists
local max = math.max
local Repairer = Addon.Repairer
local select = select
local UI = Addon.UI

-- ============================================================================
-- Functions
-- ============================================================================

-- Returns true if the dejunking process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDejunk()
  if not (_G.MerchantFrame and _G.MerchantFrame:IsShown()) then
    return false, L.CANNOT_SELL_WITHOUT_MERCHANT
  end

  if Dejunker:IsDejunking() or Confirmer:IsConfirming("Dejunker") then
    return false, L.SELLING_IN_PROGRESS
  end

  if Destroyer:IsDestroying() or Confirmer:IsConfirming("Destroyer") then
    return false, L.CANNOT_SELL_WHILE_DESTROYING
  end

  for _, listKey in pairs(Lists.LIST_KEYS) do
    if
      ListHelper:IsParsing(Lists.sell.inclusions[listKey]) or
      ListHelper:IsParsing(Lists.sell.exclusions[listKey])
    then
      return
        false,
        L.CANNOT_SELL_WHILE_LISTS_UPDATING:format(
          Lists.sell.inclusions[listKey].locale,
          Lists.sell.exclusions[listKey].locale
        )
    end
  end

  return true
end

-- Returns true if the destroying process can be safely started,
-- and false plus a reason message otherwise.
-- @return bool, string or nil
function Core:CanDestroy()
  if Destroyer:IsDestroying() or Confirmer:IsConfirming("Destroyer") then
    return false, L.DESTROYING_IN_PROGRESS
  end

  if Dejunker:IsDejunking() or Confirmer:IsConfirming("Dejunker") then
    return false, L.CANNOT_DESTROY_WHILE_SELLING
  end

  for _, listKey in pairs(Lists.LIST_KEYS) do
    if
      ListHelper:IsParsing(Lists.destroy.inclusions[listKey]) or
      ListHelper:IsParsing(Lists.destroy.exclusions[listKey])
    then
      return
        false,
        L.CANNOT_DESTROY_WHILE_LISTS_UPDATING:format(
          Lists.destroy.inclusions[listKey].locale,
          Lists.destroy.exclusions[listKey].locale
        )
    end
  end

  return true
end

--- Returns `true` and a reason message if a critical process is in progress.
--- @return boolean, string|nil
function Core:IsBusy()
  if Dejunker:IsDejunking() then
    return true, L.STATUS_SELLING_ITEMS_TEXT
  end

  if Destroyer:IsDestroying() then
    return true, L.STATUS_DESTROYING_ITEMS_TEXT
  end

  if Confirmer:IsConfirming() then
    return true, L.STATUS_CONFIRMING_ITEMS_TEXT
  end

  if ListHelper:IsParsing() then
    return true, L.STATUS_UPDATING_LISTS_TEXT
  end

  return false
end

-- ============================================================================
-- Game Update
-- ============================================================================

-- Frame
_G.CreateFrame("Frame"):SetScript("OnUpdate", function(_, elapsed)
  Core:OnUpdate(elapsed)
end)

local DELAY = 10 -- seconds
local interval = DELAY
local home, world, latency

function Core:OnUpdate(elapsed)
  interval = interval + elapsed
  if (interval >= DELAY) then -- Update latency
    interval = 0
    home, world = select(3, GetNetStats())
    latency = max(home, world) * 0.001 -- convert to seconds
    self.MinDelay = max(latency, 0.15) -- 0.15 seconds min
  end

  ListHelper:OnUpdate(elapsed)

  Dejunker:OnUpdate(elapsed)
  Destroyer:OnUpdate(elapsed)
  if Repairer.OnUpdate then Repairer:OnUpdate(elapsed) end
  Confirmer:OnUpdate(elapsed)

  UI:OnUpdate(elapsed)
end
