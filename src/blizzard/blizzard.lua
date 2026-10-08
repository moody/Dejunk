local Addon = select(2, ...) ---@type Addon

--- @class Blizzard
local B = Addon:GetModule("Blizzard")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Returns the game's global with the given `name`. Throws an error if the client does not have it.
--- @param name string
--- @return any
local function getGlobal(name)
  return _G[name] or error(("The game global `%s` does not exist on this client."):format(name), 2)
end

-- =============================================================================
-- Blizzard - Strings
-- =============================================================================

--- The game's own localized strings.
B.Strings = {
  --- Name of the Alt key.
  ALT_KEY_TEXT = getGlobal("ALT_KEY_TEXT"),

  --- Name of the Ctrl key.
  CTRL_KEY_TEXT = getGlobal("CTRL_KEY_TEXT"),

  --- Name of the Shift key.
  SHIFT_KEY_TEXT = getGlobal("SHIFT_KEY_TEXT"),

  --- Name of the Poor item quality.
  POOR_TEXT = getGlobal("ITEM_QUALITY0_DESC"),

  --- Name of the Common item quality.
  COMMON_TEXT = getGlobal("ITEM_QUALITY1_DESC"),

  --- Name of the Uncommon item quality.
  UNCOMMON_TEXT = getGlobal("ITEM_QUALITY2_DESC"),

  --- Name of the Rare item quality.
  RARE_TEXT = getGlobal("ITEM_QUALITY3_DESC"),

  --- Name of the Epic item quality.
  EPIC_TEXT = getGlobal("ITEM_QUALITY4_DESC"),

  --- Label of the Accept button.
  ACCEPT_TEXT = getGlobal("ACCEPT"),

  --- Label of the Cancel button.
  CANCEL_TEXT = getGlobal("CANCEL"),

  --- Label of the Yes button.
  YES_TEXT = getGlobal("YES"),

  --- Label of the No button.
  NO_TEXT = getGlobal("NO"),

  --- Error message shown when a vendor does not buy an item.
  VENDOR_DOESNT_BUY_ERROR_TEXT = getGlobal("ERR_VENDOR_DOESNT_BUY"),
}
