local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Consts = Addon.Consts
local Destroyables = Addon.Lists.Destroyables
local Exclusions = Addon.Lists.Exclusions
local Inclusions = Addon.Lists.Inclusions
local L = Addon.Libs.L
local ListHelper = Addon.ListHelper
local tconcat = table.concat
local Tools = Addon.Tools
local Undestroyables = Addon.Lists.Undestroyables
local Utils = Addon.UI.Utils

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Returns a localized help string indicating the purpose of the list.
-- @param {table} list
-- @return {string}
local function getListHelpText(list)
  if list == Inclusions then return L.INCLUSIONS_HELP_TEXT end
  if list == Exclusions then return L.EXCLUSIONS_HELP_TEXT end
  if list == Destroyables then return L.DESTROYABLES_HELP_TEXT end
  if list == Undestroyables then return L.UNDESTROYABLES_HELP_TEXT end
end

-- ============================================================================
-- Mixins
-- ============================================================================

local Mixins = {}

-- Creates the base UI for the list group, which consists of a TabGroup widget.
-- @param {table} parent - the parent widget
function Mixins:Create(parent)
  local tabGroup = AceGUI:Create("TabGroup")
  tabGroup:SetLayout("Fill")
  tabGroup:SetTabs({
    { text = self.list.locale, value = "List" },
    { text = L.IMPORT_TEXT, value = "Import" },
    { text = L.EXPORT_TEXT, value = "Export" }
  })

  tabGroup:SetCallback("OnGroupSelected", function(_, event, group)
    tabGroup:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:PauseLayout()

    --[[
      If `self` is UI.Groups.Inclusions, and `group` is "Import", the below
      code is equivalent to calling: UI.Groups.Inclusions:Import(scrollFrame)
    ]]
    self[group](self, scrollFrame)

    scrollFrame:ResumeLayout()
    scrollFrame:DoLayout()

    tabGroup:AddChild(scrollFrame)
  end)

  tabGroup:SelectTab("List")
  parent:AddChild(tabGroup)
end

-- Creates the UI for the list name tab, which displays a ListFrame widget.
-- @param {table} parent - the parent widget
function Mixins:List(parent)
  Utils:Heading(parent, self.list.locale)

  -- Help label
  Utils:Label({
    parent = parent,
    text = getListHelpText(self.list),
    fullWidth = true
  })

  -- Space
  Utils:Label({ parent = parent, text = " ", fullWidth = true })

  -- Add/remove help label
  Utils:Label({
    parent = parent,
    text = L.LIST_ADD_REMOVE_HELP_TEXT,
    fullWidth = true
  })

  -- ListFrame
  Utils:ListFrame({
    parent = parent,
    -- title = listText,
    list = self.list
  })

  -- Remove all button
  Utils:Button({
    parent = parent,
    text = L.REMOVE_ALL_TEXT,
    onClick = function()
      Tools:YesNoPopup({
        text = L.REMOVE_ALL_POPUP:format(self.list.localeColored),
        onAccept = function()
          self.list:RemoveAll()
        end
      })
    end
  })

  -- Sort button
  Utils:Dropdown({
    parent = parent,
    label = L.SORT_BY_TEXT,
    list = ListHelper:GetDropdownList(),
    value = ListHelper:GetDropdownValue(),
    onValueChanged = function(_, event, key)
      ListHelper:SortBy(key)
    end
  })
end

-- Creates the UI for the Import tab, which provides an EditBox for input.
-- @param {table} parent - the parent widget
function Mixins:Import(parent)
  Utils:Heading(parent, L.IMPORT_TEXT)
  Utils:Label({
    parent = parent,
    text = L.IMPORT_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Utils:MultiLineEditBox({
    parent = parent,
    fullWidth = true,
    numLines = 25
  })

  Utils:Button({
    parent = parent,
    text = L.IMPORT_TEXT,
    onClick = function()
      for itemID in editBox:GetText():gmatch('([^;]+)') do
        itemID = tonumber(itemID)
        if itemID and (itemID > 0) and (itemID <= Consts.MAX_NUMBER) then
          self.list:Add(itemID)
        end
      end

      editBox:ClearFocus()
    end
  })
end

-- Creates the UI for the Export tab, which provides an EditBox for output.
-- @param {table} parent - the parent widget
function Mixins:Export(parent)
  Utils:Heading(parent, L.EXPORT_TEXT)
  Utils:Label({
    parent = parent,
    text = L.EXPORT_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Utils:MultiLineEditBox({
    parent = parent,
    fullWidth = true,
    numLines = 25
  })

  Utils:Button({
    parent = parent,
    text = L.EXPORT_TEXT,
    onClick = function()
      local itemIDs = self.list:GetItemIDs()
      editBox:SetText(tconcat(itemIDs, ";"))
      editBox:HighlightText(0)
      editBox:SetFocus()
    end
  })
end

-------------------------------------------------------------------------------

-- Add list groups
for name, list in pairs(Addon.Lists) do
  local group = Addon.UI.Groups[name] or error("Unsupported group: " .. name)

  group.parent = "SimpleGroup"
  group.layout = "Fill"
  group.list = list

  -- Add mixins
  for k, v in pairs(Mixins) do group[k] = v end
end
