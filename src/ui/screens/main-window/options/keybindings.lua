local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local Keybindings = Addon:GetModule("Keybindings")
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
local function addKeybindingCard(group, bindingName, labelText, descriptionText)
  group:AddKeybindingCard({
    labelText = labelText,
    descriptionText = descriptionText,
    get = function()
      local key = Keybindings:GetKey(bindingName)
      if key ~= DefaultStates.UNBOUND_KEY then return key end
    end,
    set = function(key)
      if key and key ~= DefaultStates.UNBOUND_KEY then
        Keybindings:SetKey(bindingName, key)
      else
        Keybindings:RemoveKey(bindingName)
      end
    end
  })
end

-- ============================================================================
-- MainWindowOptions - Keybindings
-- ============================================================================

--- Creates the panel of keybindings.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateKeybindingsPanel()
  local panel, container = OptionsBuilder:CreatePanel({
    titleText = Colors.Blue(L.KEYBINDS),
    titleJustify = "LEFT"
  })

  -- Footer.
  local footer = OptionsBuilder:AddMessageFooter(panel)
  footer:SetOrder(1000) -- Position at the end.

  -- Windows.
  local windows = OptionsBuilder:AddGroup(container, L.WINDOWS)
  addKeybindingCard(windows, "toggleMainWindow", L.TOGGLE_MAIN_WINDOW)
  addKeybindingCard(windows, "toggleJunkFrame", L.TOGGLE_JUNK_FRAME)
  addKeybindingCard(windows, "toggleLootableFrame", L.TOGGLE_LOOTABLE_FRAME)

  -- Actions.
  local actions = OptionsBuilder:AddGroup(container, L.ACTIONS)
  addKeybindingCard(actions, "startSelling", L.START_SELLING, L.KEYBIND_DESCRIPTION_START_SELLING)
  addKeybindingCard(actions, "destroyNextItem", L.DESTROY_NEXT_ITEM)

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
    addKeybindingCard(
      entry.group,
      entry.addBindingName,
      L.ADD_TO_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_ADD_TO_LIST
    )

    addKeybindingCard(
      entry.group,
      entry.removeBindingName,
      L.REMOVE_FROM_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_REMOVE_FROM_LIST
    )
  end

  return panel
end
