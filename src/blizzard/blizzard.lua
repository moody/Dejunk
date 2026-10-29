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
-- Globals
-- =============================================================================

local BACKPACK_CONTAINER = getGlobal("BACKPACK_CONTAINER")
local C_Container = getGlobal("C_Container")
local ClearCursor = getGlobal("ClearCursor")
local ClearOverrideBindings = getGlobal("ClearOverrideBindings")
local CreateFrame = getGlobal("CreateFrame")
local CreateKeyChordStringUsingMetaKeyState = getGlobal("CreateKeyChordStringUsingMetaKeyState")
local GameTooltip = getGlobal("GameTooltip")
local GetBindingAction = getGlobal("GetBindingAction")
local GetBindingName = getGlobal("GetBindingName")
local GetBindingText = getGlobal("GetBindingText")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or getGlobal("GetCoinTextureString")
local GetContainerItemID = C_Container.GetContainerItemID
local GetContainerItemInfo = C_Container.GetContainerItemInfo
local GetContainerItemPurchaseInfo = C_Container.GetContainerItemPurchaseInfo
local GetContainerNumSlots = C_Container.GetContainerNumSlots
local GetConvertedKeyOrButton = getGlobal("GetConvertedKeyOrButton")
local GetCursorInfo = getGlobal("GetCursorInfo")
local GetItemInfo = C_Item.GetItemInfo or getGlobal("GetItemInfo")
local GetItemInfoFromHyperlink = getGlobal("GetItemInfoFromHyperlink")
local GetTime = getGlobal("GetTime")
local InCombatLockdown = getGlobal("InCombatLockdown")
local IsKeyPressIgnoredForBinding = getGlobal("IsKeyPressIgnoredForBinding")
local NUM_BAG_SLOTS = NUM_TOTAL_EQUIPPED_BAG_SLOTS or getGlobal("NUM_BAG_SLOTS")
local SetOverrideBindingClick = getGlobal("SetOverrideBindingClick")

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

  --- Prompt shown while a binding waits for a key. Takes the label of the binding and the name of the Escape key.
  ASSIGN_KEY_PROMPT_TEXT = getGlobal("SETTINGS_BIND_KEY_TO_COMMAND_OR_CANCEL"),

  --- Title of the tooltip of a bound key. Takes the label of the binding and the text of the key.
  KEY_BINDING_NAME_AND_KEY_TEXT = getGlobal("KEY_BINDING_NAME_AND_KEY"),

  --- Hint shown in the tooltip of a bound key.
  KEY_BINDING_TOOLTIP_TEXT = getGlobal("KEY_BINDING_TOOLTIP"),

  --- Message shown after a key is bound.
  KEY_BOUND_TEXT = getGlobal("KEY_BOUND"),

  --- Message shown when a key is taken from another binding. Takes the label of that binding.
  KEY_UNBOUND_ERROR_TEXT = getGlobal("KEY_UNBOUND_ERROR"),

  --- Error message shown when a vendor does not buy an item.
  VENDOR_DOESNT_BUY_ERROR_TEXT = getGlobal("ERR_VENDOR_DOESNT_BUY"),
}

-- =============================================================================
-- Blizzard - Font Objects
-- =============================================================================

--- The game's own font objects, from smallest to largest.
B.FontObjects = {
  --- Small text, 10 pixels high on a Latin client.
  --- @type Font
  Small = getGlobal("GameFontNormalSmall"),

  --- Default text, 12 pixels high on a Latin client.
  --- @type Font
  Normal = getGlobal("GameFontNormal"),

  --- Medium text, 14 pixels high on a Latin client.
  --- @type Font
  Medium = getGlobal("GameFontNormalMed2"),

  --- Large text, 16 pixels high on a Latin client.
  --- @type Font
  Large = getGlobal("GameFontNormalLarge"),
}

-- =============================================================================
-- Blizzard - Bindings
-- =============================================================================

--- Functions for override bindings, which the game does not save, and the keys they use.
B.Bindings = {}

--- Clears every override binding set for `owner`. Cannot be called in combat.
--- @param owner Frame
function B.Bindings:ClearOverrides(owner)
  ClearOverrideBindings(owner)
end

--- Makes `key` click the button named `buttonName`, taking priority over other
--- override bindings. Cannot be called in combat.
--- @param owner Frame
--- @param key string
--- @param buttonName string
function B.Bindings:SetClickOverride(owner, key, buttonName)
  SetOverrideBindingClick(owner, true, key, buttonName)
end

--- Returns the key for a key name or mouse button name with the held modifiers,
--- such as `CTRL-BUTTON4`, or `nil` for a modifier key.
--- @param input string
--- @return string? key
function B.Bindings:GetKeyFromInput(input)
  local key = GetConvertedKeyOrButton(input)
  if IsKeyPressIgnoredForBinding(key) then return nil end
  return CreateKeyChordStringUsingMetaKeyState(key)
end

--- Returns the name of the game's own binding that uses `key`, or `nil` if none
--- does. Override bindings are not included.
--- @param key string
--- @return string? name
function B.Bindings:GetGameBindingName(key)
  local action = GetBindingAction(key)
  if action ~= "" then return GetBindingName(action) end
end

--- Returns the text the game shows for a key.
--- @param key string
--- @return string text
function B.Bindings:GetKeyText(key)
  return GetBindingText(key)
end

-- =============================================================================
-- Blizzard - Container
-- =============================================================================

--- Game functions for the bags.
B.Container = {}

--- Returns an iterator over every slot in the bags, in order. Each step gives the `bag`, the `slot`, and the ID of the
--- item in it, which is `nil` for an empty slot. Usage:
--- ```
--- for bag, slot, itemId in B.Container:IterateSlots() do
---   -- Do stuff.
--- end
--- ```
--- @return function
function B.Container:IterateSlots()
  local bag, slot = BACKPACK_CONTAINER, 0
  local numSlots = GetContainerNumSlots(bag)

  return function()
    slot = slot + 1

    if slot > numSlots then
      slot = 1

      -- Move to next bag
      repeat
        bag = bag + 1
        if bag > NUM_BAG_SLOTS then return nil end
        numSlots = GetContainerNumSlots(bag)
      until numSlots > 0
    end

    return bag, slot, GetContainerItemID(bag, slot)
  end
end

-- B.Container:GetItemInfo()
do
  --- @class BagItemInfoBuffer : ContainerItemInfo
  local t = {}

  --- Returns the item in the slot as a table with the fields `bag`, `slot`, `texture`, `quantity`, `quality`,
  --- `lootable`, `link`, `noValue`, and `id`, or `nil` if the slot is empty.
  --- @param bag integer
  --- @param slot integer
  --- @return BagItemInfo? item
  function B.Container:GetItemInfo(bag, slot)
    --- @class BagItemInfo : table
    local item = GetContainerItemInfo(bag, slot)
    if type(item) ~= "table" then return nil end

    for k in pairs(t) do t[k] = nil end
    for k in pairs(item) do
      t[k] = item[k]
      item[k] = nil
    end

    item.bag = bag
    item.slot = slot
    item.texture = t.iconFileID
    item.quantity = t.stackCount
    item.quality = t.quality
    item.lootable = t.hasLoot
    item.link = t.hyperlink
    item.noValue = t.hasNoValue
    item.id = t.itemID

    return item
  end
end

--- Returns the seconds left to refund the item in the slot, or `nil` if it has no refund window.
--- @param bag integer
--- @param slot integer
--- @return number? seconds
function B.Container:GetRefundSeconds(bag, slot)
  local purchaseInfo = GetContainerItemPurchaseInfo(bag, slot, false)
  return purchaseInfo and purchaseInfo.refundSeconds
end

-- =============================================================================
-- Blizzard - Cursor
-- =============================================================================

--- Functions for the item held on the cursor.
B.Cursor = {}

--- Returns the ID of the item held on the cursor, or `nil` if it holds no item.
--- @return number? itemId
function B.Cursor:GetItemId()
  local infoType, itemId = GetCursorInfo()
  if infoType == "item" then return itemId end
end

--- Empties the cursor.
function B.Cursor:Clear()
  ClearCursor()
end

-- =============================================================================
-- Blizzard - Item
-- =============================================================================

--- Game functions for items.
B.Item = {}

--- Returns the name, base item level, inventory type, price, class ID, and subclass ID of an item, or `nil` until it
--- is cached.
--- @param item string | number Item ID, link, or name.
--- @return string? name
--- @return number? baseItemLevel
--- @return string? invType
--- @return number? price Of one item, in copper.
--- @return number? classId
--- @return number? subclassId
function B.Item:GetInfo(item)
  local name, _, _, baseItemLevel, _, _, _, _, invType, _, price, classId, subclassId = GetItemInfo(item)
  return name, baseItemLevel, invType, price, classId, subclassId
end

-- =============================================================================
-- Blizzard - Money
-- =============================================================================

--- Game functions for money.
B.Money = {}

--- Returns the amount of copper as text with coin icons.
--- @param copper number
--- @return string
function B.Money:GetCoinText(copper)
  return GetCoinTextureString(copper)
end

-- =============================================================================
-- Blizzard - Tooltip
-- =============================================================================

--- Functions for reading the game tooltip.
B.Tooltip = {}

--- Returns the ID of the item shown in the game tooltip, or `nil` if it shows
--- no item.
--- @return number? itemId
function B.Tooltip:GetItemId()
  local name, link = GameTooltip:GetItem()
  if name and link then return (GetItemInfoFromHyperlink(link)) end
end

-- =============================================================================
-- Blizzard - Utils
-- =============================================================================

--- Game functions that have no group of their own yet.
B.Utils = {}

--- Creates a frame.
--- @generic T
--- @param frameType `T` | FrameType
--- @param name? string
--- @param parent? Frame
--- @param template? string
--- @return T frameType
function B.Utils:CreateFrame(frameType, name, parent, template)
  return CreateFrame(frameType, name, parent, template)
end

--- Returns the current time in seconds. It is the same for every call within a frame.
--- @return number
function B.Utils:GetTime()
  return GetTime()
end

--- Returns `true` while the game blocks protected actions, such as changing
--- keybindings.
--- @return boolean
function B.Utils:InCombatLockdown()
  return InCombatLockdown()
end
