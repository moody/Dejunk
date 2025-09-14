local Addon = select(2, ...) ---@type Addon

--- @class TSM
local TSM = Addon:GetModule("TSM")

-- ============================================================================
-- TSM
-- ============================================================================

--- Returns the TSM disenchant value for the given `itemLink`.
--- @param itemLink string
--- @return number|nil
function TSM:GetDisenchantValue(itemLink)
  if not TSM_API then return nil end

  local itemString = TSM_API.ToItemString(itemLink)
  if not itemString then return nil end

  local value, err = TSM_API.GetCustomPriceValue("Destroy", itemString)
  if err then
    return nil
  end

  return value
end
