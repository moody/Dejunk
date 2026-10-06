local Addon = select(2, ...) ---@type Addon

--- @class Coins
local Coins = Addon:GetModule("Coins")

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = COPPER_PER_SILVER * 100

--- Returns the total copper of the given gold, silver, and copper.
--- @param gold integer
--- @param silver integer
--- @param copper integer
--- @return integer totalCopper
function Coins:Combine(gold, silver, copper)
  return gold * COPPER_PER_GOLD + silver * COPPER_PER_SILVER + copper
end

--- Returns the gold, silver, and copper that make up the given total copper.
--- @param totalCopper integer
--- @return integer gold, integer silver, integer copper
function Coins:Split(totalCopper)
  local gold = math.floor(totalCopper / COPPER_PER_GOLD)
  local silver = math.floor((totalCopper % COPPER_PER_GOLD) / COPPER_PER_SILVER)
  local copper = totalCopper % COPPER_PER_SILVER
  return gold, silver, copper
end
