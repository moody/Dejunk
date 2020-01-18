-- Tools: a collection of helpful functions.

local _, Addon = ...
local Consts = Addon.Consts
local DCL = Addon.Libs.DCL
local GetContainerItemPurchaseInfo = _G.GetContainerItemPurchaseInfo
local L = Addon.Libs.L
local LE_ITEM_QUALITY_EPIC = _G.LE_ITEM_QUALITY_EPIC
local LE_ITEM_QUALITY_POOR = _G.LE_ITEM_QUALITY_POOR
local StaticPopup_Show = _G.StaticPopup_Show
local Tools = Addon.Tools

-- ============================================================================
-- String Functions
-- ============================================================================

-- Formats a tooltip string to indicate that the option does not apply to poor
-- quality items.
-- @param {string} tooltip - the tooltip to format
-- @return {string}
function Tools:DoesNotApplyToPoor(tooltip)
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
function Tools:GetItemIDFromLink(itemLink)
  return (itemLink and itemLink:match("item:(%d+)")) or nil
end

-- Returns true if the specified item can be sold.
-- @param item - the item
function Tools:ItemCanBeSold(item)
  return (
    not item.NoValue and
    item.Price > 0 and
    item.Quality >= LE_ITEM_QUALITY_POOR and
    item.Quality <= LE_ITEM_QUALITY_EPIC
  )
end

-- Returns true if the specified item can be destroyed.
-- @param item - the item
function Tools:ItemCanBeDestroyed(item)
  -- Disallow destruction of Pet Cages
  if Addon.IS_RETAIL and item.Class == Consts.BATTLEPET_CLASS then
    return false
  end

  return (
    item.Quality >= LE_ITEM_QUALITY_POOR and
    item.Quality <= LE_ITEM_QUALITY_EPIC
  )
end

-- Returns true if the specified item can be refunded.
-- @param item - the item
function Tools:ItemCanBeRefunded(item)
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
  function Tools:YesNoPopup(options)
    DEJUNK_YES_NO_POPUP.text = options.text
    DEJUNK_YES_NO_POPUP.OnAccept = options.onAccept
    DEJUNK_YES_NO_POPUP.OnCancel = options.onCancel
    DEJUNK_YES_NO_POPUP.OnShow = options.onShow
    DEJUNK_YES_NO_POPUP.OnHide = options.onHide
    StaticPopup_Show("DEJUNK_YES_NO_POPUP")
  end
end
