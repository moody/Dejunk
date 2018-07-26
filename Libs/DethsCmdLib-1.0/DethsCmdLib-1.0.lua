local MAJOR, MINOR = "DethsCmdLib-1.0", 1

-- LibStub
local DCL, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not DCL then return end

-- Upvalues
local _G, assert, type, format, tostring, strlower, strupper, unpack =
      _G, assert, type, format, tostring, strlower, strupper, unpack

-- Variables
local cmdList = {}

-- Creates a slash command assigned to the specified function. All arguments
-- following the slash command will be extracted and passed to the specified
-- function whenever the slash command is invoked.
-- @param cmd - the slash command name (e.g. "myaddon")
-- @param func - the function to be called when the slash command is invoked
function DCL:Create(cmd, func)
  assert(type(cmd) == "string", "cmd must be a string")
  assert(type(func) == "function", "func must be a function")
  -- Assert alphanumeric characters only
  local invalidChar = cmd:match("%W")
  assert(not invalidChar, format("cmd \"%s\" contains invalid character: \"%s\"", cmd, tostring(invalidChar)))

  local cmdLower, cmdUpper = strlower(cmd), strupper(cmd)
  
  assert(not cmdList[cmdLower], format("a slash command \"%s\" already exists", cmdLower))
  cmdList[cmdLower] = true
  
  -- Register slash command
  _G[format("SLASH_%s1", cmdUpper)] = "/"..cmdLower

  -- Assign slash command function
  SlashCmdList[cmdUpper] = function(msg, editBox)
    -- Extract command args
    -- Example: "/myaddon arg1 arg2 arg3"
    -- args = {"arg1", "arg2", "arg3"}
    local args = {}
    for arg in msg:gmatch("[^%s]+") do args[#args+1] = arg end
    -- Call func with args
    func(unpack(args))
  end
end
