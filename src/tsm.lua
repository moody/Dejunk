local Addon = select(2, ...) ---@type Addon

--- @class TSM
local TSM = Addon:GetModule("TSM")

local tooltip = CreateFrame("GameTooltip", "DejunkTsmTooltip", UIParent, "GameTooltipTemplate")
local disenchantPattern = "Disenchant %(%d+g ?%d+s ?%d+c?%)"
local destroyPattern = "Destroy %(%d+g ?%d+s ?%d+c?%)"

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Parses a gold/silver/copper string and returns the total copper value.
--- @param valueString string
--- @return number|nil
local function parseCurrency(valueString)
  local g, s, c = valueString:match("(%d+)g ?(%d+)s ?(%d+)c")
  if not g then
    g, s = valueString:match("(%d+)g ?(%d+)s")
  end
  if not (g or s) then
    s, c = valueString:match("(%d+)s ?(%d+)c")
  end
  if not (g or s or c) then
    g = valueString:match("(%d+)g")
  end
  if not (g or s or c) then
    s = valueString:match("(%d+)s")
  end
  if not (g or s or c) then
    c = valueString:match("(%d+)c")
  end

  g = tonumber(g) or 0
  s = tonumber(s) or 0
  c = tonumber(c) or 0

  return (g * 10000) + (s * 100) + c
end

-- ============================================================================
-- TSM
-- ============================================================================

--- Returns the TSM disenchant value for the given `itemLink`.
--- @param itemLink string
--- @return number|nil
function TSM:GetDisenchantValue(itemLink)
  if not TSMAPI then return nil end

  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:SetHyperlink(itemLink)

  for i = 2, tooltip:NumLines() do
    local line = _G[tooltip:GetName() .. "TextLeft" .. i]
    if line then
      local text = line:GetText()
      if text then
        local disenchantMatch = strmatch(text, disenchantPattern)
        if disenchantMatch then
          return parseCurrency(disenchantMatch)
        end
        local destroyMatch = strmatch(text, destroyPattern)
        if destroyMatch then
          return parseCurrency(destroyMatch)
        end
      end
    end
  end

  return nil
end
