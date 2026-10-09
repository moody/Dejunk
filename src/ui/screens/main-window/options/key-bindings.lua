local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- MainWindowOptions - Key Bindings
-- ============================================================================

--- Creates the panel of key bindings.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateKeyBindingsPanel()
  local panel, container = OptionsBuilder:CreatePanel({
    titleText = Colors.Blue(L.KEYBINDS),
    titleJustify = "LEFT"
  })

  -- Footer.
  local footer = OptionsBuilder:AddMessageFooter(panel)
  footer:SetOrder(1000) -- Position at the end.

  -- Windows.
  local windows = OptionsBuilder:AddGroup(container, L.WINDOWS)

  windows:AddKeyBindingCard({
    labelText = L.TOGGLE_MAIN_WINDOW,
    get = function() Addon:Debug("KeyBindingCard: get ->", L.TOGGLE_MAIN_WINDOW) end,
    set = function(key) Addon:Debug("KeyBindingCard: set ->", L.TOGGLE_MAIN_WINDOW, key) end
  })

  windows:AddKeyBindingCard({
    labelText = L.TOGGLE_JUNK_FRAME,
    get = function() Addon:Debug("KeyBindingCard: get ->", L.TOGGLE_JUNK_FRAME) end,
    set = function(key) Addon:Debug("KeyBindingCard: set ->", L.TOGGLE_JUNK_FRAME, key) end
  })

  windows:AddKeyBindingCard({
    labelText = L.TOGGLE_LOOTABLE_FRAME,
    get = function() Addon:Debug("KeyBindingCard: get ->", L.TOGGLE_LOOTABLE_FRAME) end,
    set = function(key) Addon:Debug("KeyBindingCard: set ->", L.TOGGLE_LOOTABLE_FRAME, key) end
  })

  -- Actions.
  local actions = OptionsBuilder:AddGroup(container, L.ACTIONS)

  actions:AddKeyBindingCard({
    labelText = L.START_SELLING,
    descriptionText = L.KEYBIND_DESCRIPTION_START_SELLING,
    get = function() Addon:Debug("KeyBindingCard: get ->", L.START_SELLING) end,
    set = function(key) Addon:Debug("KeyBindingCard: set ->", L.START_SELLING, key) end
  })

  actions:AddKeyBindingCard({
    labelText = L.DESTROY_NEXT_ITEM,
    get = function() Addon:Debug("KeyBindingCard: get ->", L.DESTROY_NEXT_ITEM) end,
    set = function(key) Addon:Debug("KeyBindingCard: set ->", L.DESTROY_NEXT_ITEM, key) end
  })

  -- Lists.
  local profileLists = OptionsBuilder:AddGroup(container, L.PROFILE_LISTS)
  local globalLists = OptionsBuilder:AddGroup(container, L.GLOBAL_LISTS)

  for _, entry in ipairs({
    { group = globalLists, inclusions = Lists.GlobalInclusions, exclusions = Lists.GlobalExclusions },
    { group = profileLists, inclusions = Lists.ProfileInclusions, exclusions = Lists.ProfileExclusions }
  }) do
    for _, list in ipairs({ entry.inclusions, entry.exclusions }) do
      local addText = L.ADD_TO_LIST:format(list.name)
      local removeText = L.REMOVE_FROM_LIST:format(list.name)

      entry.group:AddKeyBindingCard({
        labelText = addText,
        descriptionText = L.KEYBIND_DESCRIPTION_ADD_TO_LIST,
        get = function() Addon:Debug("KeyBindingCard: get ->", addText) end,
        set = function(key) Addon:Debug("KeyBindingCard: set ->", addText, key) end
      })

      entry.group:AddKeyBindingCard({
        labelText = removeText,
        descriptionText = L.KEYBIND_DESCRIPTION_REMOVE_FROM_LIST,
        get = function() Addon:Debug("KeyBindingCard: get ->", removeText) end,
        set = function(key) Addon:Debug("KeyBindingCard: set ->", removeText, key) end
      })
    end
  end

  return panel
end
