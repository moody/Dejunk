local _, Addon = ...
if not Addon.IS_RETAIL then return end

local DB = Addon.DB
local DTL = Addon.Libs.DTL
local Filter = {}
local L = Addon.Libs.L
local PlayerHasToy = _G.PlayerHasToy

local REASON = Addon.Filters:DestroyReason(
  L.BY_TYPE_TEXT,
  L.DESTROY_TOYS_ALREADY_COLLECTED_TEXT
)

function Filter:Run(item)
  if DB.Profile.destroy.byType.toysAlreadyCollected and item.NoValue then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if DTL:IsSoulbound() and PlayerHasToy(item.ItemID) then
        return "JUNK", REASON
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
