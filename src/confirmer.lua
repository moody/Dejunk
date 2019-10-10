-- Confirmer: confirms that items have been either dejunked or destroyed and prints messages.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DBL = Addon.Libs.DBL

-- Upvalues
local assert, format, pairs, tremove = assert, format, pairs, table.remove
local GetCoinTextureString = GetCoinTextureString

-- Addon
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DB = Addon.DB

-- Variables
local MAX_ATTEMPTS = 50
local confirmAttempts = {
  -- [item] = count
}

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
    if not DB.Profile.VerboseMode and (self.count > 0) then
      if (self.count == 1) then
        Core:Print(L.DESTROYED_ITEM)
      else
        Core:Print(format(L.DESTROYED_ITEMS, self.count))
      end
    end
  end
end

-- ============================================================================
-- Confirmer Functions
-- ============================================================================

do -- OnUpdate(), called in Core:OnUpdate()
  local interval = 0

  function Confirmer:OnUpdate(elapsed)
    interval = interval + elapsed
    if (interval >= Core.MinDelay) then
      interval = 0

      -- Confirm module items
      for _, module in pairs(Modules) do
        if (#module.Items > 0) then
          for i=1, #module.Items do Confirmer:ConfirmNextItem(module) end
        elseif module.finalMessageQueued then
          module:PrintFinalMessage()
          module.finalMessageQueued = nil
        end
      end
    end
  end
end

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

  if DBL:StillInBags(item) then -- Give the item a chance to finish updating
    local count = (confirmAttempts[item] or 0) + 1
    if (count >= MAX_ATTEMPTS) then -- Stop trying to confirm
      confirmAttempts[item] = nil
      Core:Print(format(module.CANNOT_CONFIRM, item.ItemLink))
    else -- Try again later
      -- Core:Debug("Confirmer", format("[%s, %s, %s] = %s", item.Bag, item.Slot, item.ItemID, count))
      confirmAttempts[item] = count
      module.Items[#module.Items+1] = item
    end

    return
  end

  -- Bag and slot is empty, so the item should have been sold or destroyed
  if (item.Quantity == 1) then
    Core:PrintVerbose(format(module.CONFIRM_ITEM_VERBOSE, item.ItemLink))
  else
    Core:PrintVerbose(format(module.CONFIRM_ITEMS_VERBOSE, item.ItemLink, item.Quantity))
  end

  confirmAttempts[item] = nil
  module:OnConfirm(item)
end
