local _, Addon = ...
local Commands = Addon.Commands
local Group = Addon.UI.Groups.Commands
local L = Addon.Libs.L
local Widgets = Addon.UI.Widgets

local function add(parent, cmd)
  parent = Widgets:InlineGroup({
    parent = parent,
    fullWidth = true,
    title = cmd.title,
  })

  Widgets:Label({
    parent = parent,
    fullWidth = true,
    text = cmd.help,
  })

  parent = Widgets:InlineGroup({
    parent = parent,
    fullWidth = true,
    title = L.USAGE_TEXT,
  })

  Widgets:Label({
    parent = parent,
    fullWidth = true,
    text = "/dejunk " .. cmd.usage,
  })
end

function Group:Create(parent)
  Widgets:Heading(parent, L.COMMANDS_TEXT)
  for _, cmd in ipairs(Commands()) do add(parent, cmd) end
end
