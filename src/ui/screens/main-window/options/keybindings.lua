local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local DefaultStates = Addon:GetModule("DefaultStates")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Keybindings = Addon:GetModule("Keybindings")
local L = Addon:GetModule("Locale")
local Lists = Addon:GetModule("Lists")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")
local TickerManager = Addon:GetModule("TickerManager")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

--- Labels of the bindings that have a card, by binding name.
--- @type table<BindingName, string>
local labels = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Adds a card to `group` for the key of a binding.
--- @param group OptionsBuilderGroup
--- @param footer OptionsBuilderMessageFooter
--- @param bindingName BindingName
--- @param labelText string
--- @param descriptionText? string
local function addKeybindingCard(group, footer, bindingName, labelText, descriptionText)
  labels[bindingName] = labelText

  group:AddKeybindingCard({
    labelText = labelText,
    descriptionText = descriptionText,
    get = function()
      local key = Keybindings:GetKey(bindingName)
      if key ~= DefaultStates.UNBOUND_KEY then return B.Bindings:GetKeyText(key) end
    end,
    isListening = function()
      return Keybindings:GetListeningBindingName() == bindingName
    end,
    onClick = function(mouseButton)
      if mouseButton == "LeftButton" then
        if Keybindings:GetListeningBindingName() == bindingName then
          Keybindings:StopListening()
        else
          Keybindings:StartListening(bindingName)
        end
      elseif mouseButton == "RightButton" then
        if Keybindings:GetKey(bindingName) ~= DefaultStates.UNBOUND_KEY then
          Keybindings:RemoveKey(bindingName)
          footer:SetMessage(nil)
        end
      else
        Keybindings:ProcessInput(mouseButton)
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
    titleText = Colors.Blue(L.KEYBINDINGS),
    titleJustify = "LEFT",
    interceptMouseWheel = function(delta)
      if not Keybindings:GetListeningBindingName() then return false end
      Keybindings:ProcessInput(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
      return true
    end
  })

  -- Footer.
  local footer = OptionsBuilder:AddMessageFooter(panel, { color = Colors.White, defaultMessage = L.KEYBINDINGS_PRIORITY_NOTE })
  footer:SetOrder(1000) -- Position at the end.

  -- Stop listening and reset the footer when hidden. Disable and dim the panel while keybindings cannot be changed.
  panel:WhenFrameReady(function(frame)
    frame:HookScript("OnHide", function()
      Keybindings:StopListening()
      footer:SetMessage(nil)
    end)

    TickerManager:NewTicker(0.1, function()
      local isLocked = Keybindings:IsLocked()
      frame:FireEvent("ENABLED", not isLocked)
      frame:SetAlpha(isLocked and 0.5 or 1)
    end):BindFrame(frame)
  end)

  EventManager:On(E.KeybindingListeningChanged, function(bindingName)
    footer:SetMessage(
      bindingName and
      Colors.Gold(
        B.Strings.ASSIGN_KEY_PROMPT_TEXT:format(
          Colors.White(labels[bindingName]),
          Colors.White(B.Bindings:GetKeyText("ESCAPE"))
        )
      )
      or nil
    )
  end)

  EventManager:On(E.KeybindingBound, function(_, key, replacedBindingName, gameBindingName)
    local lines = {}

    if replacedBindingName then
      lines[#lines + 1] = Colors.Red(B.Strings.KEY_UNBOUND_ERROR_TEXT:format(Colors.White(labels[replacedBindingName])))
    end

    if gameBindingName then
      lines[#lines + 1] = Colors.Gold(
        L.KEY_ALSO_USED_BY_GAME:format(
          Colors.White(B.Bindings:GetKeyText(key)),
          Colors.White(gameBindingName)
        )
      )
    end

    footer:SetMessage(#lines > 0 and table.concat(lines, "|n") or B.Strings.KEY_BOUND_TEXT)
  end)

  -- Windows.
  local windows = OptionsBuilder:AddGroup(container, L.WINDOWS)
  addKeybindingCard(windows, footer, "toggleMainWindow", L.TOGGLE_MAIN_WINDOW)
  addKeybindingCard(windows, footer, "toggleJunkFrame", L.TOGGLE_JUNK_FRAME)
  addKeybindingCard(windows, footer, "toggleLootableFrame", L.TOGGLE_LOOTABLE_FRAME)

  -- Actions.
  local actions = OptionsBuilder:AddGroup(container, L.ACTIONS)
  addKeybindingCard(actions, footer, "startSelling", L.START_SELLING, L.KEYBIND_DESCRIPTION_START_SELLING)
  addKeybindingCard(actions, footer, "destroyNextItem", L.DESTROY_NEXT_ITEM)

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
      footer,
      entry.addBindingName,
      L.ADD_TO_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_ADD_TO_LIST
    )

    addKeybindingCard(
      entry.group,
      footer,
      entry.removeBindingName,
      L.REMOVE_FROM_LIST:format(entry.list.name),
      L.KEYBIND_DESCRIPTION_REMOVE_FROM_LIST
    )
  end

  return panel
end
