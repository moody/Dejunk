local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local KeyBindings = Addon:GetModule("KeyBindings")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Adds a card to `group` for the key of a binding.
--- @param group OptionsBuilderGroup
--- @param bindingName BindingName
--- @param labelText string
--- @param descriptionText? string
local function addBindingCard(group, bindingName, labelText, descriptionText)
  group:AddKeyBindingCard({
    labelText = labelText,
    descriptionText = descriptionText,
    get = function()
      local key = KeyBindings:GetKey(bindingName)
      if key ~= DefaultStates.UNBOUND_KEY then return key end
    end,
    set = function(key)
      if key and key ~= DefaultStates.UNBOUND_KEY then
        KeyBindings:SetKey(bindingName, key)
      else
        KeyBindings:RemoveKey(bindingName)
      end
    end
  })
end

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
  addBindingCard(windows, "toggleMainWindow", L.TOGGLE_MAIN_WINDOW)
  addBindingCard(windows, "toggleJunkFrame", L.TOGGLE_JUNK_FRAME)
  addBindingCard(windows, "toggleLootableFrame", L.TOGGLE_LOOTABLE_FRAME)

  -- Actions.
  local actions = OptionsBuilder:AddGroup(container, L.ACTIONS)
  addBindingCard(actions, "startSelling", L.START_SELLING, L.KEYBIND_DESCRIPTION_START_SELLING)
  addBindingCard(actions, "destroyNextItem", L.DESTROY_NEXT_ITEM)

  -- Lists.
  local profileLists = OptionsBuilder:AddGroup(container, L.PROFILE_LISTS)
  local globalLists = OptionsBuilder:AddGroup(container, L.GLOBAL_LISTS)

  for _, entry in ipairs({
    {
      group = globalLists,
      list = Lists.GlobalInclusions,
      addBindingName = "addToGlobalInclusions",
      removeBindingName = "removeFromGlobalInclusions"
    },
    {
      group = globalLists,
      list = Lists.GlobalExclusions,
      addBindingName = "addToGlobalExclusions",
      removeBindingName = "removeFromGlobalExclusions"
    },
    {
      group = profileLists,
      list = Lists.ProfileInclusions,
      addBindingName = "addToProfileInclusions",
      removeBindingName = "removeFromProfileInclusions"
    },
    {
      group = profileLists,
      list = Lists.ProfileExclusions,
      addBindingName = "addToProfileExclusions",
      removeBindingName = "removeFromProfileExclusions"
    }
  }) do
    addBindingCard(
      entry.group,
      entry.addBindingName,
      L.ADD_TO_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_ADD_TO_LIST
    )

    addBindingCard(
      entry.group,
      entry.removeBindingName,
      L.REMOVE_FROM_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_REMOVE_FROM_LIST
    )
  end

  return panel
end
