local _, Addon = ...
if not Addon.IS_RETAIL then return end

local Consts = Addon.Consts
local DB = Addon.DB
local DTL = Addon.Libs.DTL
local Filter = {}
local L = Addon.Libs.L

-- "Collected (%d/%d)" -> "Collected (.*)"
local ITEM_PET_KNOWN_CAPTURE = _G.ITEM_PET_KNOWN:gsub("%%d/%%d", ".*")

local REASON = Addon.Filters:DestroyReason(
  L.BY_TYPE_TEXT,
  L.DESTROY_PETS_ALREADY_COLLECTED_TEXT
)

function Filter:Run(item)
  if
    DB.Profile.destroy.byType.petsAlreadyCollected and
    item.SubClass == Consts.COMPANION_SUBCLASS and
    item.NoValue
  then
    if not DTL:ScanBagSlot(item.Bag, item.Slot) then
      return Addon.Filters:IncompleteTooltipError()
    else -- Tooltip can be scanned
      if
        DTL:IsSoulbound() and
        (not not DTL:Match(false, ITEM_PET_KNOWN_CAPTURE))
      then
        return "JUNK", REASON
      end
    end
  end

  return "PASS"
end

Addon.Filters:Add(Addon.Destroyer, Filter)
