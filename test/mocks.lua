--- @diagnostic disable: undefined-global, missing-fields

--- Methods that create mocks for the tests.
--- @class DejunkMocks
local Mocks = {}

--- Returns a mock frame, recording what is done to it under `._test`. Only a `Button` or `EditBox` has
--- `SetEnabled()`, and only an `EditBox` has the edit focus scripts.
--- @param frameType? string Defaults to `Frame`.
--- @param parent? table
--- @return DejunkMockFrame
function Mocks:CreateFrame(frameType, parent)
  --- @class DejunkMockFrame
  local MockFrame = {
    --- What was done to the frame, apart from the fields that the code under test sets.
    _test = {
      --- The parent the frame was created with.
      parent = parent,
      --- Functions from `HookScript()`, by script.
      --- @type table<string, function[]>
      hooks = {},
      --- Events from `RegisterEvent()`.
      --- @type table<string, boolean>
      registered = {},
      --- Functions from `SetScript()`.
      --- @type table<string, function>
      scripts = {},
      --- Last value from `SetEnabled()`.
      enabled = true
    }
  }

  function MockFrame:GetParent()
    return self._test.parent
  end

  function MockFrame:HookScript(name, fn)
    self._test.hooks[name] = self._test.hooks[name] or {}
    table.insert(self._test.hooks[name], fn)
  end

  function MockFrame:HasScript(name)
    return frameType == "EditBox" and name:find("EditFocus") ~= nil
  end

  function MockFrame:RegisterEvent(event)
    self._test.registered[event] = true
  end

  function MockFrame:SetScript(name, fn)
    self._test.scripts[name] = fn
  end

  function MockFrame:SetClipsChildren() end

  function MockFrame:SetWidth() end

  function MockFrame:SetHeight() end

  if frameType == "Button" or frameType == "EditBox" then
    function MockFrame:SetEnabled(enabled)
      self._test.enabled = enabled
    end
  end

  return MockFrame
end

return Mocks
