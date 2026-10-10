local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local B = Addon:GetModule("Blizzard")
local Commands = Addon:GetModule("Commands")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Lists = Addon:GetModule("Lists")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class KeyBindings
local KeyBindings = Addon:GetModule("KeyBindings")

--- Owner of every override binding Dejunk sets.
local owner = B.Utils:CreateFrame("Frame")

--- Hidden buttons keyed by binding name.
--- @type table<BindingName, Button>
local buttons = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Adds the item shown in the game tooltip to a list.
--- @param listKey ListKey
local function addToList(listKey)
  local itemId = B.Tooltip:GetItemId()
  if itemId then Lists[listKey]:Add(itemId) end
end

--- Removes the item shown in the game tooltip from a list.
--- @param listKey ListKey
local function removeFromList(listKey)
  local itemId = B.Tooltip:GetItemId()
  if itemId then Lists[listKey]:Remove(itemId) end
end

--- Runs the command of each binding, by binding name. Mirrors keys in `DefaultStates.Global.keyBindings`.
--- @type table<BindingName, function>
local handlers = {
  toggleMainWindow = Commands.options,
  toggleJunkFrame = Commands.junk,
  toggleLootableFrame = Commands.loot,
  startSelling = Commands.sell,
  destroyNextItem = Commands.destroy,
  addToProfileInclusions = function() addToList("ProfileInclusions") end,
  removeFromProfileInclusions = function() removeFromList("ProfileInclusions") end,
  addToProfileExclusions = function() addToList("ProfileExclusions") end,
  removeFromProfileExclusions = function() removeFromList("ProfileExclusions") end,
  addToGlobalInclusions = function() addToList("GlobalInclusions") end,
  removeFromGlobalInclusions = function() removeFromList("GlobalInclusions") end,
  addToGlobalExclusions = function() addToList("GlobalExclusions") end,
  removeFromGlobalExclusions = function() removeFromList("GlobalExclusions") end
}

--- Returns the hidden button for a binding, creating it if needed.
--- @param bindingName BindingName
--- @return Button
local function getButton(bindingName)
  if not buttons[bindingName] then
    local button = B.Utils:CreateFrame("Button", "DejunkKeyBinding_" .. bindingName)
    button:SetScript("OnClick", handlers[bindingName])
    buttons[bindingName] = button
  end

  return buttons[bindingName]
end

--- Clears every override binding and sets the saved keys again.
local function refreshOverrides()
  B.Bindings:ClearOverrides(owner)

  for bindingName, key in pairs(StateManager:GetGlobalState().keyBindings) do
    if handlers[bindingName] and key ~= DefaultStates.UNBOUND_KEY then
      B.Bindings:SetClickOverride(owner, key, getButton(bindingName):GetName())
    end
  end
end

--- Refreshes the overrides once the player is out of combat.
--- @type function
local debounceRefresh
debounceRefresh = TickerManager:NewDebouncer(0.1, function()
  if KeyBindings:IsLocked() then return debounceRefresh() end
  refreshOverrides()
end)

-- ============================================================================
-- KeyBindings
-- ============================================================================

--- Returns `true` while key bindings cannot be changed.
--- @return boolean
function KeyBindings:IsLocked()
  return B.Utils:InCombatLockdown()
end

--- Returns the key saved for a binding, or the default if it is unbound.
--- @param bindingName BindingName
--- @return string key
function KeyBindings:GetKey(bindingName)
  return StateManager:GetGlobalState().keyBindings[bindingName] or DefaultStates.UNBOUND_KEY
end

--- Saves a key for a binding. Returns the name of an existing binding if one had the
--- key set previously.
--- @param bindingName BindingName
--- @param key string
--- @return BindingName? replacedBindingName
function KeyBindings:SetKey(bindingName, key)
  if key == DefaultStates.UNBOUND_KEY then return self:RemoveKey(bindingName) end

  local patch = { [bindingName] = key }
  local replacedBindingName

  for otherBindingName, otherKey in pairs(StateManager:GetGlobalState().keyBindings) do
    if otherBindingName ~= bindingName and otherKey == key then
      patch[otherBindingName] = DefaultStates.UNBOUND_KEY
      replacedBindingName = otherBindingName
    end
  end

  StateManager:Dispatch(ActionCreators.Global.patchKeyBindings(patch))
  return replacedBindingName
end

--- Removes the key saved for a binding.
--- @param bindingName BindingName
function KeyBindings:RemoveKey(bindingName)
  StateManager:Dispatch(ActionCreators.Global.patchKeyBindings({ [bindingName] = DefaultStates.UNBOUND_KEY }))
end

--- Sets the saved keys again, debouncing until lockdown ends if necessary.
function KeyBindings:Refresh()
  if self:IsLocked() then
    debounceRefresh()
  else
    refreshOverrides()
  end
end

-- ============================================================================
-- Events
-- ============================================================================

local keyBindings

-- Refresh when the saved keys change, which includes the first update after login.
EventManager:On(E.StateUpdated, function(state)
  if state.global.keyBindings ~= keyBindings then
    keyBindings = state.global.keyBindings
    KeyBindings:Refresh()
  end
end)
