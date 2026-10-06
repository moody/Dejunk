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
    --- Every call to a stubbed key, in order, as `{ key, ...args }`.
    --- The mock is left out when a method is called with `:`.
    --- @type table[]
    calls = {}
  }

  --- Replaces `mock[key]` with a function that records its calls and returns nothing.
  --- @param key string
  --- @return MockSpyStub
  function Spy:Stub(key)
    --- @class MockSpyStub
    local Stub = {
      --- Every call to this key, in order, as `{ ...args }`.
      --- The mock is left out when a method is called with `:`.
      --- @type table[]
      calls = {}
    }

    local implementation = function() end

    mock[key] = function(...)
      -- Skip self when the mock is the first argument.
      local skipped = (...) == mock and 1 or 0
      local argCount = select("#", ...) - skipped

      -- Copy by position so nils stay in place.
      local args = {}
      for i = 1, argCount do
        args[i] = (select(skipped + i, ...))
      end

      -- The stub logs the arguments, and the spy logs them after the key.
      Stub.calls[#Stub.calls + 1] = args
      Spy.calls[#Spy.calls + 1] = { key, unpack(args, 1, argCount) }

      return implementation(...)
    end

    --- Sets what the stubbed function returns. Returns the stub.
    --- @param ... any
    --- @return MockSpyStub
    function Stub:Returns(...)
      -- Store the number of values, since # is unreliable with nils.
      local results = { n = select("#", ...), ... }
      implementation = function() return unpack(results, 1, results.n) end
      return self
    end

    --- Sets a function to run on each call instead, with the arguments as passed, including the mock for a method.
    --- Returns the stub.
    --- @param fn function
    --- @return MockSpyStub
    function Stub:Invokes(fn)
      implementation = fn
      return self
    end

    return Stub
  end

  return Spy
end

return Mocks
