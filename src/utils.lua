local _, Addon = ...
local Consts = Addon.Consts
local DCL = Addon.Libs.DCL
local GetContainerItemPurchaseInfo = _G.GetContainerItemPurchaseInfo
local ItemQuality = Addon.ItemQuality
local L = Addon.Libs.L
local LE_ITEM_ARMOR_COSMETIC = _G.LE_ITEM_ARMOR_COSMETIC
local LE_ITEM_ARMOR_GENERIC = _G.LE_ITEM_ARMOR_GENERIC
local LE_ITEM_WEAPON_FISHINGPOLE = _G.LE_ITEM_WEAPON_FISHINGPOLE
local LE_ITEM_WEAPON_GENERIC = _G.LE_ITEM_WEAPON_GENERIC
local StaticPopup_Show = _G.StaticPopup_Show
local Utils = Addon.Utils

-- ============================================================================
-- String Functions
-- ============================================================================

-- Formats a tooltip string to indicate that the option does not apply to poor
-- quality items.
-- @param {string} tooltip - the tooltip to format
-- @return {string}
function Utils:DoesNotApplyToPoor(tooltip)
  return ("%s|n|n%s"):format(
    tooltip,
    L.DOES_NOT_APPLY_TO_QUALITY:format(
      DCL:ColorString(L.POOR_TEXT, DCL.Wow.Poor)
    )
  )
end

-- ============================================================================
-- Item Functions
-- ============================================================================

-- Gets the item id from a specified item link.
-- @return - the item id, or nil
function Utils:GetItemIDFromLink(itemLink)
  return (itemLink and itemLink:match("item:(%d+)")) or nil
end

do -- Utils:IsEquipmentItem()
  -- Special check required for these generic armor types.
  local SPECIAL_ARMOR_EQUIPSLOTS = {
    ["INVTYPE_FINGER"] = true,
    ["INVTYPE_NECK"] = true,
    ["INVTYPE_TRINKET"] = true,
    ["INVTYPE_HOLDABLE"] = true
  }

  -- Returns true if the item is an equippable item; excluding generic
  -- armor/weapon types, cosmetic items, and fishing poles.
  -- @return {boolean}
  function Utils:IsEquipmentItem(item)
    if item.Class == Consts.ARMOR_CLASS then
      if SPECIAL_ARMOR_EQUIPSLOTS[item.EquipSlot] then return true end
      local armorType = Consts.ARMOR_SUBCLASSES[item.SubClass]
      return (
        armorType ~= LE_ITEM_ARMOR_GENERIC and
        armorType ~= LE_ITEM_ARMOR_COSMETIC
      )
    elseif item.Class == Consts.WEAPON_CLASS then
      local weaponType = Consts.WEAPON_SUBCLASSES[item.SubClass]
      return (
        weaponType ~= LE_ITEM_WEAPON_GENERIC and
        weaponType ~= LE_ITEM_WEAPON_FISHINGPOLE
      )
    end

    return false
  end
end

-- Returns true if the specified item can be sold.
-- @param item - the item
function Utils:ItemCanBeSold(item)
  return (
    not item.NoValue and
    item.Price > 0 and
    item.Quality >= ItemQuality.Poor and
    item.Quality <= ItemQuality.Epic
  )
end

-- Returns true if the specified item can be destroyed.
-- @param item - the item
function Utils:ItemCanBeDestroyed(item)
  -- Disallow destruction of Pet Cages
  if Addon.IS_RETAIL and item.Class == Consts.BATTLEPET_CLASS then
    return false
  end

  return (
    item.Quality >= ItemQuality.Poor and
    item.Quality <= ItemQuality.Epic
  )
end

-- Returns true if the specified item can be refunded.
-- @param item - the item
function Utils:ItemCanBeRefunded(item)
  local refundTimeRemaining = select(3, GetContainerItemPurchaseInfo(item.Bag, item.Slot))
  return refundTimeRemaining and (refundTimeRemaining > 0)
end

-- ============================================================================
-- Popup Functions
-- ============================================================================

do -- DEJUNK_YES_NO_POPUP
  local DEJUNK_YES_NO_POPUP = {
    button1 = _G.YES,
    button2 = _G.NO,
    showAlert = 1,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1
  }
  _G.StaticPopupDialogs.DEJUNK_YES_NO_POPUP = DEJUNK_YES_NO_POPUP

  --[[
    Shows a simple Yes or No popup for confirming an action.

    options = {
      text = string,
      onAccept = function,
      onCancel = function,
      onShow = function,
      onHide = function
    }
  ]]
  function Utils:YesNoPopup(options)
    DEJUNK_YES_NO_POPUP.text = options.text
    DEJUNK_YES_NO_POPUP.OnAccept = options.onAccept
    DEJUNK_YES_NO_POPUP.OnCancel = options.onCancel
    DEJUNK_YES_NO_POPUP.OnShow = options.onShow
    DEJUNK_YES_NO_POPUP.OnHide = options.onHide
    StaticPopup_Show("DEJUNK_YES_NO_POPUP")
  end
end
