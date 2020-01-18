-- https://github.com/moody/DethsCmdLib

-- DethsLibLoader
local DCMDL = DethsLibLoader:Create("DethsCmdLib", "1.0")
if not DCMDL then return end

-- Upvalues
local _G, assert, error, format, select, strlower, strupper, type, unpack =
      _G, assert, error, format, select, strlower, strupper, type, unpack

local cmdArgs = {}
local addonCount = {}

-- Returns nil if the command is valid, otherwise returns an error message.
local function isInvalidCommand(cmd)
  cmd = strlower(cmd)

  -- Commands cannot contain spaces, obviously
  if cmd:find(" ", 1, true) then
    return format("invalid slash command: \"%s\" contains spaces", cmd)
  end

  -- Do not overwrite slash commands that already exist
  for k, v in pairs(_G) do
    -- if value starts with "/" and key contains "SLASH"
    if (type(v) == "string") and v:match("^/") and k:find("SLASH", 1, true) then
      if (v:sub(2) == cmd) then -- v:sub(2) removes "/"
        return format("invalid slash command: \"%s\" already exists", cmd)
      end
    end
  end
end

-- Sets up a slash command.
local function createCommand(addonName, cmd)
  addonName, cmd = strupper(addonName), strlower(cmd)
  -- Create numbered slash command key
  addonCount[addonName] = (addonCount[addonName] or 0) + 1
  local slashCmdKey = ("SLASH_"..addonName..addonCount[addonName])
  -- Register slash command
  _G[slashCmdKey] = "/"..cmd
end

-- Creates a slash command assigned to the specified function for the specified
-- addon name. When the slash command is invoked, the function will be called
-- and passed a vararg (...) of extracted arguments.
-- @param addonName - the name of the addon to create a slash command for
-- @param func - the function to be called when a slash command is invoked
-- @param ... - vararg of additional slash commands that will also call the
-- specified function. If one of these slash commands already exist
-- (e.g. "camp", "who", etc.), then it will be silently skipped.
function DCMDL:Create(addonName, func, ...)
  assert(type(addonName) == "string", "addonName must be a string")
  assert(type(func) == "function", "func must be a function")

  -- Validate and setup command for addonName
  local message = isInvalidCommand(addonName)
  if message then error(message) end
  createCommand(addonName, addonName)

  -- Validate and setup additional commands
  for i=1, select("#", ...) do
    local cmd = select(i, ...)
    assert(type(cmd) == "string", "cmd must be a string")
    -- Create command if it is valid, otherwise silently skip
    if not isInvalidCommand(cmd) then
      createCommand(addonName, cmd)
    end
  end

  -- Assign function to slash commands
  SlashCmdList[strupper(addonName)] = function(msg)
    -- Extract command args
    -- Example: "/myaddon arg1 arg2 arg3"
    -- args = {"arg1", "arg2", "arg3"}
    for k in pairs(cmdArgs) do cmdArgs[k] = nil end
    for arg in msg:gmatch("[^%s]+") do cmdArgs[#cmdArgs+1] = arg end
    func(unpack(cmdArgs))
  end
end
