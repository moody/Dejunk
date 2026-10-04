--- @diagnostic disable: undefined-global, missing-fields

--- Methods that create mocks for the tests.
--- @class DejunkMocks
local Mocks = {}

--- Returns a mock frame, recording what is done to it under `._test`.
--- @return DejunkMockFrame
function Mocks:CreateFrame()
  --- @class DejunkMockFrame
  local MockFrame = {
    --- What was done to the frame, apart from the fields that the code under test sets.
    _test = {
      --- Events from `RegisterEvent()`.
      --- @type table<string, boolean>
      registered = {},
      --- Functions from `SetScript()`.
      --- @type table<string, function>
      scripts = {}
    }
  }

  function MockFrame:RegisterEvent(event)
    self._test.registered[event] = true
  end

  function MockFrame:SetScript(name, fn)
    self._test.scripts[name] = fn
  end

  return MockFrame
end

return Mocks
