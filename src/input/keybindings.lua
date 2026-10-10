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

--- @class Keybindings
local Keybindings = Addon:GetModule("Keybindings")

--- The binding waiting for a key, or `nil` while none is.
--- @type BindingName?
Keybindings.listeningBindingName = nil

--- Stops listening once keybindings are locked. Only runs while listening.
Keybindings.lockTicker = TickerManager:NewTicker(0.05, function()
  if Keybindings:IsLocked() then Keybindings:StopListening() end
end)
Keybindings.lockTicker:Cancel()

--- Hidden buttons keyed by binding name.
--- @type table<BindingName, Button>
local buttons = {}

--- Owner of every override binding Dejunk sets. It also receives keyboard
--- input while a binding is waiting for a key.
local BindingFrame = B.Utils:CreateFrame("Frame", nil, UIParent)
BindingFrame:EnableKeyboard(false)
BindingFrame:SetSize(1, 1)
BindingFrame:SetPoint("CENTER")
BindingFrame:SetScript("OnKeyDown", function(_, key) Keybindings:ProcessInput(key) end)

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

--- Runs each binding's command. Mirrors the keys of `DefaultStates.Global.keybindings`.
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
    local button = B.Utils:CreateFrame("Button", "DejunkKeybinding_" .. bindingName)
    button:SetScript("OnClick", handlers[bindingName])
    buttons[bindingName] = button
  end

  return buttons[bindingName]
end

--- Clears every override binding and sets the saved keys again.
local function refreshOverrides()
  B.Bindings:ClearOverrides(BindingFrame)

  for bindingName, key in pairs(StateManager:GetGlobalState().keybindings) do
    if handlers[bindingName] and key ~= DefaultStates.UNBOUND_KEY then
      B.Bindings:SetClickOverride(BindingFrame, key, getButton(bindingName):GetName())
    end
  end
end

--- Refreshes the overrides once the player is out of combat.
--- @type function
local debounceRefresh
debounceRefresh = TickerManager:NewDebouncer(0.1, function()
  if Keybindings:IsLocked() then return debounceRefresh() end
  refreshOverrides()
end)

-- ============================================================================
-- Keybindings
-- ============================================================================

--- Returns `true` while keybindings cannot be changed.
--- @return boolean
function Keybindings:IsLocked()
  return B.Utils:InCombatLockdown()
end

--- Returns the key saved for a binding, or `UNBOUND_KEY` if it has none.
--- @param bindingName BindingName
--- @return string key
function Keybindings:GetKey(bindingName)
  return StateManager:GetGlobalState().keybindings[bindingName] or DefaultStates.UNBOUND_KEY
end

--- Saves a key for a binding. Returns the name of an existing binding if one had the
--- key set previously.
--- @param bindingName BindingName
--- @param key string
--- @return BindingName? replacedBindingName
function Keybindings:SetKey(bindingName, key)
  if key == DefaultStates.UNBOUND_KEY then return self:RemoveKey(bindingName) end

  local patch = { [bindingName] = key }
  local replacedBindingName

  for otherBindingName, otherKey in pairs(StateManager:GetGlobalState().keybindings) do
    if otherBindingName ~= bindingName and otherKey == key then
      patch[otherBindingName] = DefaultStates.UNBOUND_KEY
      replacedBindingName = otherBindingName
    end
  end

  StateManager:Dispatch(ActionCreators.Global.patchKeybindings(patch))
  return replacedBindingName
end

--- Removes the key saved for a binding.
--- @param bindingName BindingName
function Keybindings:RemoveKey(bindingName)
  StateManager:Dispatch(ActionCreators.Global.patchKeybindings({ [bindingName] = DefaultStates.UNBOUND_KEY }))
end

--- Sets the saved keys again, debouncing until lockdown ends if necessary.
function Keybindings:Refresh()
  if self:IsLocked() then
    debounceRefresh()
  else
    refreshOverrides()
  end
end

--- Returns the binding waiting for a key, or `nil` while none is.
--- @return BindingName? bindingName
function Keybindings:GetListeningBindingName()
  return self.listeningBindingName
end

--- Starts waiting for the next input to bind to a binding. Does nothing while locked.
--- @param bindingName BindingName
function Keybindings:StartListening(bindingName)
  if self:IsLocked() then return end
  self:StopListening()

  self.listeningBindingName = bindingName
  BindingFrame:EnableKeyboard(true)
  self.lockTicker:Restart()

  Addon:Debug("Keybindings: listening for", bindingName) -- TEMP: debug
end

--- Binds the input to the binding waiting for a key, then stops listening.
--- Escape stops without binding. Does nothing while no binding is waiting.
--- @param input string Key name or mouse button name.
function Keybindings:ProcessInput(input)
  if not self.listeningBindingName then return end

  if input == "ESCAPE" then
    self:StopListening()
    return
  end

  local key = B.Bindings:GetKeyFromInput(input)
  if not key then return end

  self:StopListening()

  Addon:Debug("Keybindings: would bind", self.listeningBindingName, key) -- TEMP: debug
end

--- Stops waiting for an input.
function Keybindings:StopListening()
  if not self.listeningBindingName then return end

  Addon:Debug("Keybindings: stopped listening for", self.listeningBindingName) -- TEMP: debug

  self.listeningBindingName = nil
  BindingFrame:EnableKeyboard(false)
  self.lockTicker:Cancel()
end

-- ============================================================================
-- Events
-- ============================================================================

--- The saved keybindings as of the last refresh.
local keybindings

-- Refresh when the saved keys change, which includes the first update after login.
EventManager:On(E.StateUpdated, function(state)
  if state.global.keybindings ~= keybindings then
    keybindings = state.global.keybindings
    Keybindings:Refresh()
  end
end)
