-- Confirmer: confirms that items have been either dejunked or destroyed and prints messages.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL

-- Upvalues
local assert, tremove = assert, table.remove
local GetCoinTextureString = GetCoinTextureString

-- Addon
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DejunkDB = Addon.DejunkDB

-- Data for modules which use Confirmer
local Modules = {
  Dejunker = { Items = {} },
  Destroyer = { Items = {} }
}

do -- Dejunker module data
  local module = Modules.Dejunker

  -- Locale strings
  module.CANNOT_CONFIRM = L.MAY_NOT_HAVE_SOLD_ITEM
  module.CONFIRM_ITEM_VERBOSE = L.SOLD_ITEM_VERBOSE
  module.CONFIRM_ITEMS_VERBOSE = L.SOLD_ITEMS_VERBOSE
  
  function module:OnStart()
    self.profit = 0
  end
  
  function module:OnConfirm(item)
    self.profit = self.profit + (item.Price * item.Quantity)
  end

  function module:PrintFinalMessage()
    if (self.profit > 0) then
      Core:Print(format(L.SOLD_YOUR_JUNK, GetCoinTextureString(self.profit)))
    end
  end
end

do -- Destroyer module data
  local module = Modules.Destroyer

  -- Locale strings
  module.CANNOT_CONFIRM = L.MAY_NOT_HAVE_DESTROYED_ITEM
  module.CONFIRM_ITEM_VERBOSE = L.DESTROYED_ITEM_VERBOSE
  module.CONFIRM_ITEMS_VERBOSE = L.DESTROYED_ITEMS_VERBOSE

  function module:OnStart()
    self.count = 0
    -- self.loss = 0
  end

  function module:OnConfirm(item)
    self.count = self.count + item.Quantity
    -- self.loss = self.loss + (item.Price * item.Quantity)
  end

  function module:PrintFinalMessage()
    -- Show basic message if not printing verbose
    if not DejunkDB.SV.VerboseMode then
      if (self.count == 1) then
        Core:Print(L.DESTROYED_ITEM)
      else
        Core:Print(format(L.DESTROYED_ITEMS, self.count))
      end
    end
  end
end

-- ============================================================================
-- Confirmer Frame
-- ============================================================================

do
  local frame = CreateFrame("Frame", AddonName.."ConfirmerFrame")
  local DELAY = 0.1 -- 0.1sec
  local interval = 0

  function frame:OnUpdate(elapsed)
    interval = interval + elapsed
    if (interval >= DELAY) then
      interval = 0

      -- Confirm module items
      for _, module in pairs(Modules) do
        if (#module.Items > 0) then
          Confirmer:ConfirmNextItem(module)
        elseif module.finalMessageQueued then
          module:PrintFinalMessage()
          module.finalMessageQueued = nil
        end
      end
    end
  end

  frame:SetScript("OnUpdate", frame.OnUpdate)
end

-- ============================================================================
-- Confirmer Functions
-- ============================================================================

function Confirmer:IsConfirming(moduleName)
  if moduleName then
    assert(Modules[moduleName])
    local module = Modules[moduleName]
    return (#module.Items > 0) or module.finalMessageQueued
  else
    for _, module in pairs(Modules) do
      if (#module.Items > 0) or module.finalMessageQueued then return true end
    end
  end
end

function Confirmer:Start(moduleName)
  assert(Modules[moduleName])
  local module = Modules[moduleName]
  module:OnStart()
end

function Confirmer:Queue(moduleName, item)
  assert(Modules[moduleName])
  local module = Modules[moduleName]
  module.Items[#module.Items+1] = item
end

function Confirmer:Stop(moduleName)
  assert(Modules[moduleName])
  local module = Modules[moduleName]
  module.finalMessageQueued = true
end

-- Main confirmation function
function Confirmer:ConfirmNextItem(module)
  local item = tremove(module.Items, 1)
  if not item then return end

  if DBL:StillInBags(item) then
    if item:IsLocked() then -- Item probably being sold or destroyed, add it back to list and try again later
      module.Items[#module.Items+1] = item
    else -- Item is still in bags, so it cannot be confirmed
      Core:Print(format(module.CANNOT_CONFIRM, item.ItemLink))
      DBL:Release(item)
    end
    
    return
  end

  -- Bag and slot is empty, so the item should have been sold or destroyed
  if (item.Quantity == 1) then
    Core:PrintVerbose(format(module.CONFIRM_ITEM_VERBOSE, item.ItemLink))
  else
    Core:PrintVerbose(format(module.CONFIRM_ITEMS_VERBOSE, item.ItemLink, item.Quantity))
  end

  module:OnConfirm(item)
  DBL:Release(item)
end
