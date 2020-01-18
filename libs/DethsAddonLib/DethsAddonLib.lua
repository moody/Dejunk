-- https://github.com/moody/DethsAddonLib

local LibName, LibVersion = "DethsAddonLib", "1.0"

-- DethsLibLoader
local DAL = DethsLibLoader:Create(LibName, LibVersion)
if not DAL then return end

-- Upvalues
local assert, type = assert, type

-- Variables
local Addons = {}
local AddonMixins = {}
local EventListeners = {}

-- ============================================================================
-- Frame
-- ============================================================================

local frame = CreateFrame("Frame", format("%s_%s_Frame", LibName, LibVersion))

do -- Frame scripts
  frame:SetScript("OnUpdate", function(self, elapsed)
    for _, t in pairs(Addons) do t:OnUpdate(elapsed) end
  end)

  local function onEvent(self, event, ...)
    if EventListeners[event] then
      for listener in pairs(EventListeners[event]) do
        listener:OnEvent(event, ...)
      end
    end
  end

  local function initial_onEvent(self, event, ...)
    if (event == "PLAYER_LOGIN") then
      self:UnregisterEvent(event)
      self:SetScript("OnEvent", onEvent)
      for _, t in pairs(Addons) do
        t:OnInitialize()
        t.OnInitialize = nil
      end
    end
  end

  frame:SetScript("OnEvent", initial_onEvent)
  frame:RegisterEvent("PLAYER_LOGIN")
end

-- ============================================================================
-- Addon Mixins
-- ============================================================================

-- Called once when the addon is fully loaded. Override as required.
AddonMixins.OnInitialize = nop
-- Called on each update. Override as required.
AddonMixins.OnUpdate = nop
-- Called when a registered event fires. Override as required.
AddonMixins.OnEvent = nop

function AddonMixins:RegisterEvent(event)
  if (event == "PLAYER_LOGIN") then return end
  if not EventListeners[event] then
    EventListeners[event] = {}
    frame:RegisterEvent(event)
  end
  EventListeners[event][self] = true
end

function AddonMixins:UnregisterEvent(event)
  if EventListeners[event] then EventListeners[event][self] = nil end
end

function AddonMixins:UnregisterAllEvents()
  for _, event in pairs(EventListeners) do event[self] = nil end
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Creates and returns a table with generic addon functions.
-- @param addonName - the name of the addon
function DAL:Create(addonName)
  assert(type(addonName) == "string", "addonName must be a string")
  assert(not Addons[addonName], addonName.." already registered")

  -- Create addon table
  local addon = {}
  -- Add mixins
  for k, v in pairs(AddonMixins) do addon[k] = v end
  -- Register
  Addons[addonName] = addon
  -- Return
  return addon
end
