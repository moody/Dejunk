local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local StateManager = Addon:GetModule("StateManager")
local TSM = Addon:GetModule("TSM")
local TickerManager = Addon:GetModule("TickerManager")
local Actions = Addon:GetModule("Actions")

--- @class TsmAutoJunker
local TsmAutoJunker = Addon:GetModule("TsmAutoJunker")

local processedItems = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

local function processItem(item)
  if processedItems[item.id] then return end

  local tsmSettings = StateManager:GetCurrentState().includeByTsmDisenchant
  if not (tsmSettings.enabled and tsmSettings.autoJunkOnLoot) then return end

  local expansion = Addon.IS_RETAIL and "retail" or Addon.IS_WRATH and "wrath" or Addon.IS_CATA and "cata" or Addon.IS_MISTS and "mop" or "classic"
  if not tsmSettings[expansion] then return end

  local retryCount = 0
  local maxRetries = 5
  local retryDelay = 1

  local function tryGetTsmValue()
    local disenchantValue = TSM:GetDisenchantValue(item.link)
    if disenchantValue then
      if item.price > disenchantValue then
        StateManager:GetStore():Dispatch(Actions:AddTsmJunkItem(item.id))
      else
        StateManager:GetStore():Dispatch(Actions:RemoveTsmJunkItem(item.id))
      end
      processedItems[item.id] = true
    else
      retryCount = retryCount + 1
      if retryCount <= maxRetries then
        TickerManager:After(retryDelay, tryGetTsmValue)
      end
    end
  end

  tryGetTsmValue()
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.BagsUpdated, function()
  local tsmSettings = StateManager:GetCurrentState().includeByTsmDisenchant
  if not (tsmSettings.enabled and tsmSettings.autoJunkOnLoot) then return end

  processedItems = {}
  local items = Items:GetItems()
  for _, item in ipairs(items) do
    processItem(item)
  end
end)
