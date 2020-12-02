local _, Addon = ...
local Colors = Addon.Colors
local Commands = Addon.Commands
local DCL = Addon.Libs.DCL
local Group = Addon.UI.Groups.Commands
local L = Addon.Libs.L
local Widgets = Addon.UI.Widgets

local function add(parent, cmd)
  local group = Widgets:InlineGroup({
    parent = parent,
    fullWidth = true,
    title = DCL:ColorString(cmd.keyword, Colors.Primary),
  })

  -- Help text.
  Widgets:Label({
    parent = group,
    fullWidth = true,
    text = cmd.help,
  })

  -- Usage.
  Widgets:Label({
    parent = Widgets:InlineGroup({
      parent = group,
      fullWidth = true,
      title = DCL:ColorString(L.USAGE_TEXT, Colors.Yellow),
    }),
    fullWidth = true,
    text = cmd.usage,
  })

  return group
end

local function addAll(parent, commands)
  for _, cmd in ipairs(commands) do
    local group = add(parent, cmd)

    if next(cmd.subcommands) then
      group = Widgets:InlineGroup({
        parent = group,
        fullWidth = true,
        title = DCL:ColorString(L.SUBCOMMANDS_TEXT, Colors.Green),
      })

      addAll(group, cmd.subcommands())
    end
  end
end

function Group:Create(parent)
  Widgets:Heading(parent, L.COMMANDS_TEXT)
  addAll(parent, Commands())
end
