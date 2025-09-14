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
  print("Dejunk TSM Debug: GetDisenchantValue called for itemLink: " .. tostring(itemLink))
  if not TSM_API then
    print("Dejunk TSM Debug: TSM_API not found.")
    return nil
  end

  local itemString = TSM_API.ToItemString(itemLink)
  if not itemString then
    print("Dejunk TSM Debug: TSM_API.ToItemString returned nil for itemLink: " .. tostring(itemLink))
    return nil
  end
  print("Dejunk TSM Debug: itemString: " .. tostring(itemString))

  local value, err = TSM_API.GetCustomPriceValue("Disenchant", itemString)
  if err then
    print("Dejunk TSM Debug: Error getting disenchant value for " .. itemString .. ": " .. tostring(err))
    return nil
  end

  print("Dejunk TSM Debug: Disenchant value for " .. itemString .. ": " .. tostring(value))
  return value
end
