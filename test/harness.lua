--- @diagnostic disable: undefined-global, missing-fields

-- ============================================================================
-- Harness
-- ============================================================================

--- @class DejunkTestHarness
local Harness = {
  --- Addon name passed to each loaded file.
  ADDON_NAME = "Dejunk"
}

--- Returns a test context with its own addon table and globals. `setup` runs once, before any file is loaded, to
--- set the WoW globals the files need and to seed modules.
--- @param setup? fun(globals: table<string, any>, addon: Addon)
--- @return DejunkTestContext Context
function Harness:NewContext(setup)
  --- The globals the files see. Writes stay here, and reads fall through to the real `_G`. Tests never modify
  --- `_G`: they set the WoW globals they need in `setup`.
  --- @type table<string, any>
  local globals = setmetatable({
    -- WoW globals read while `src/addon.lua` loads.
    C_AddOns = { GetAddOnMetadata = function(str) return str end },
    LibStub = function() return {} end
  }, { __index = _G })

  globals._G = globals

  --- @class DejunkTestContext
  local Context = {
    --- The addon table that the loaded files share.
    --- @type Addon
    Addon = {}
  }

  --- Executes a source file with the context's globals, passing `ADDON_NAME` and `Addon`.
  --- @param path string
  local function run(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, globals)
    chunk(Harness.ADDON_NAME, Context.Addon)
  end

  run("src/addon.lua")
  run("libs/Wux.lua")
  assert(Context.Addon.Wux, "Wux failed to load")

  if setup then setup(globals, Context.Addon) end

  --- Loads a source file into the context. Returns the context.
  --- @param path string
  --- @return DejunkTestContext Context
  function Context:Load(path)
    run(path)
    return self
  end

  --- Returns the context's module with the given name.
  --- @param name string
  --- @return table
  function Context:GetModule(name)
    return self.Addon:GetModule(name)
  end

  return Context
end

--- Reads a SavedVariables file and returns the table it assigns, without creating a global. The file must assign
--- exactly one variable.
--- @param path string
--- @return table
function Harness:ReadSavedVariablesFile(path)
  local env = {}
  setfenv(assert(loadfile(path)), env)()
  local name, value = next(env)
  assert(name and next(env, name) == nil, path .. " must assign exactly one variable")
  return value
end

return Harness
