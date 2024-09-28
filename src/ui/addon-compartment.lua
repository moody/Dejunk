if not AddonCompartmentFrame then return end

local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Commands = Addon:GetModule("Commands")

AddonCompartmentFrame:RegisterAddon({
  text = ADDON_NAME,
  icon = Addon:GetAsset("dejunk-icon"),
  notCheckable = true,
  func = Commands.options
})
