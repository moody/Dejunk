--- Helpers for nested tables addressed by dot-separated paths. Keys must be strings without dots.
--- @class DejunkTestTableUtils
local TableUtils = {}

-- ============================================================================
-- TableUtils
-- ============================================================================

--- Returns the value at `path` in `t`, or `nil` if a key along the path is missing.
--- @param t table
--- @param path string
--- @return any
function TableUtils:GetByPath(t, path)
  for key in path:gmatch("[^%.]+") do
    if type(t) ~= "table" then return nil end
    t = t[key]
  end
  return t
end

--- Sets the value at `path` in `t`. Fails at the caller's line if a parent table is missing.
--- @param t table
--- @param path string
--- @param value any
function TableUtils:SetByPath(t, path, value)
  local keys = {}
  for key in path:gmatch("[^%.]+") do table.insert(keys, key) end
  for i = 1, #keys - 1 do
    t = t[keys[i]]
    if type(t) ~= "table" then error("missing parent table at `" .. keys[i] .. "`", 2) end
  end
  t[keys[#keys]] = value
end

return TableUtils
