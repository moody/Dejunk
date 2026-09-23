--- Predicates for use as `assert(Matchers:Method(...))`. Each returns `true`, or `false` and a message.
--- @class DejunkTestMatchers
local Matchers = {}

-- ============================================================================
-- Matchers
-- ============================================================================

--- Returns `true` if `a` and `b` are deeply equal, otherwise `false` and a message naming a differing path, such
--- as `.global.safeSell`. Tables are compared by contents, other values with `==`. Cyclic tables are not supported.
--- @param a any
--- @param b any
--- @param path? string Prefix for the reported path. Omit at the top level.
--- @return boolean equal
--- @return string? message
function Matchers:IsDeepEqual(a, b, path)
  path = path or ""

  if type(a) ~= "table" or type(b) ~= "table" then
    if a ~= b then return false, "values differ at `" .. path .. "`" end
    return true
  end

  for key, value in pairs(a) do
    local equal, message = self:IsDeepEqual(value, b[key], path .. "." .. tostring(key))
    if not equal then return false, message end
  end

  for key in pairs(b) do
    if a[key] == nil then return false, "values differ at `" .. path .. "." .. tostring(key) .. "`" end
  end

  return true
end

--- Returns `true` if `t` has no keys other than `keys`, otherwise `false` and a message naming an unexpected key.
--- @param t table
--- @param keys string[]
--- @return boolean ok
--- @return string? message
function Matchers:HasNoKeysOtherThan(t, keys)
  local set = {}
  for _, key in ipairs(keys) do set[key] = true end
  for key in pairs(t) do
    if not set[key] then return false, "unexpected key: " .. tostring(key) end
  end
  return true
end

return Matchers
