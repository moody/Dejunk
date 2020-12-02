local _, Addon = ...
local Commands = Addon.Commands
local Group = Addon.UI.Groups.Commands
local L = Addon.Libs.L
local Widgets = Addon.UI.Widgets

local function add(parent, cmd)
  local group = Widgets:InlineGroup({
    parent = parent,
    fullWidth = true,
    title = cmd.title,
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
      title = L.USAGE_TEXT,
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
        title = L.SUBCOMMANDS_TEXT,
      })

      addAll(group, cmd.subcommands())
    end
  end
end

function Group:Create(parent)
  Widgets:Heading(parent, L.COMMANDS_TEXT)
  addAll(parent, Commands())
end
