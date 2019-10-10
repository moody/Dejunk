local _, Addon = ...
if not Addon.IS_CLASSIC then return end

local Consts = Addon.Consts
local DB = Addon.DB
local Filter = {}
local GetItemCount = _G.GetItemCount
local L = Addon.Libs.L
local tremove = table.remove

function Filter:Run(item)
  if
    Consts.PLAYER_CLASS == "WARLOCK" and
    DB.Profile.DestroyExcessSoulShards.Enabled and
    item.ItemID == Consts.SOUL_SHARD_ITEM_ID and
    GetItemCount(Consts.SOUL_SHARD_ITEM_ID) >
    DB.Profile.DestroyExcessSoulShards.Value
  then
    return "JUNK", L.REASON_DESTROY_EXCESS_SOUL_SHARDS_TEXT
  end

  return "PASS"
end

-- Remove soul shards not in excess from the list so they do not get destroyed.
function Filter:After(items)
  local totalShards = GetItemCount(Consts.SOUL_SHARD_ITEM_ID)
  local numToDestroy = totalShards - DB.Profile.DestroyExcessSoulShards.Value

  if numToDestroy <= 0 then -- Remove all
    for i, item in ipairs(items) do
      if item.ItemID == Consts.SOUL_SHARD_ITEM_ID then tremove(items, i) end
    end
  else -- Remove shards not in excess
    local numToRemove = totalShards - numToDestroy
    for i = #items, 1, -1 do
      local item = items[i]
      if numToRemove > 0 and item.ItemID == Consts.SOUL_SHARD_ITEM_ID then
        numToRemove = numToRemove - 1
        tremove(items, i)
      end
    end
  end
end

Addon.Filters:Add(Addon.Destroyer, Filter)
