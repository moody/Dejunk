--- @diagnostic disable: undefined-global, missing-fields

--- Methods that create mocks for the tests.
--- @class DejunkMocks
local Mocks = {}

--- Returns a mock frame, recording what is done to it under `._test`. Only a `Button` or `EditBox` has
--- `SetEnabled()`, and only an `EditBox` has the edit focus scripts.
--- @param frameType? string Defaults to `Frame`.
--- @param parent? table
--- @return MockFrame
function Mocks:CreateFrame(frameType, parent)
  --- @class MockFrame
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
      enabled = true,
      --- Last value from `SetPropagateMouseClicks()`.
      propagatesClicks = false,
      --- Last value from `SetPropagateMouseMotion()`.
      propagatesMotion = false
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

  function MockFrame:SetPropagateMouseClicks(propagate)
    self._test.propagatesClicks = propagate
  end

  function MockFrame:SetPropagateMouseMotion(propagate)
    self._test.propagatesMotion = propagate
  end

  if frameType == "Button" or frameType == "EditBox" then
    function MockFrame:SetEnabled(enabled)
      self._test.enabled = enabled
    end
  end

  return MockFrame
end

--- Returns a spy for the given `mock` table. Stubs replace its keys and are never restored, so spy only on a table
--- made for the test.
--- @param mock table
--- @return MockSpy
function Mocks:CreateSpy(mock)
  --- @class MockSpy
  local Spy = {
    --- Every call to a stubbed key, in order, as `{ key, ...arguments }`. The mock is left out when a method is
    --- called with `:`.
    --- @type table[]
    calls = {}
  }

  --- Replaces `mock[key]` with a function that records its calls and returns nothing.
  --- @param key string
  --- @return MockSpyStub
  function Spy:Stub(key)
    local results = { n = 0 }

    mock[key] = function(...)
      -- Skip self when the mock is the first argument.
      local first = (...) == mock and 2 or 1
      local call = { key }
      -- Copy by position so nils stay in place.
      for i = first, select("#", ...) do
        call[i - first + 2] = (select(i, ...))
      end
      self.calls[#self.calls + 1] = call
      -- Return exactly the stored values, including nils.
      return unpack(results, 1, results.n)
    end

    --- @class MockSpyStub
    local Stub = {}

    --- Sets what the stubbed function returns. Returns the stub.
    --- @param ... any
    --- @return MockSpyStub
    function Stub:Returns(...)
      -- Store the count, since # is unreliable with nils.
      results = { n = select("#", ...), ... }
      return self
    end

    return Stub
  end

  return Spy
end

return Mocks
