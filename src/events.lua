local ADDON_NAME, Addon = ...
local E = Addon.Events

local events = {
  -- DB
  "ProfileChanged",

  -- Lists
  "ListItemAdded"
}

for i, event in pairs(events) do
  assert(E[event] == nil)
  E[event] = ("%s_EVENT_%s"):format(ADDON_NAME, i)
end
