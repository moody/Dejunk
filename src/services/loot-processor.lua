local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local Lists = Addon:GetModule("Lists")
local StateManager = Addon:GetModule("StateManager")
local TSM = Addon:GetModule("TSM")
local TickerManager = Addon:GetModule("TickerManager")

--- @class LootProcessor
local LootProcessor = Addon:GetModule("LootProcessor")

-- ============================================================================
-- Local Functions
-- ============================================================================

local function processItem(itemLink)
  local tsmSettings = StateManager:GetCurrentState().includeByTsmDisenchant
  if not (tsmSettings.enabled and tsmSettings.autoJunkOnLoot) then return end

  local expansion = Addon.IS_RETAIL and "retail" or Addon.IS_WRATH and "wrath" or Addon.IS_CATA and "cata" or Addon.IS_MISTS and "mop" or "classic"
  if not tsmSettings[expansion] then return end

  local retryCount = 0
  local maxRetries = 5
  local retryDelay = 1

  local function tryGetTsmValue()
    local disenchantValue = TSM:GetDisenchantValue(itemLink)
    if disenchantValue then
      local itemInfo = C_Item.GetItemInfo(itemLink)
      if itemInfo and itemInfo.itemSellPrice and itemInfo.itemSellPrice > disenchantValue then
        local itemId = itemInfo.itemID
        if itemId then
          Lists:Add(Lists.PerCharInclusions, itemId)
        end
      end
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

EventManager:On(E.Wow.ChatMsgLoot, function(_, msg)
  local _, _, itemLink = strfind(msg, "(|Hitem:.-|h%[.-%]|h)")
  if itemLink then
    processItem(itemLink)
  end
end)
