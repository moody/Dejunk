local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Consts = Addon.Consts
local L = Addon.Libs.L
local ListHelper = Addon.ListHelper
local tconcat = table.concat
local Utils = Addon.Utils
local Widgets = Addon.UI.Widgets

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
    { text = L.PROFILE_TEXT, value = "Profile" },
    { text = L.GLOBAL_TEXT, value = "Global" },
  })

  tabGroup:SetCallback("OnGroupSelected", function(_, _, group)
    tabGroup:ReleaseChildren()
    self:AddTab(tabGroup, (
      group == "Global" and
      self.listGroup.global or
      self.listGroup.profile
    ))
  end)

  tabGroup:SelectTab("Profile")
  parent:AddChild(tabGroup)
end

-- Creates the base UI for the list group, which consists of a TabGroup widget.
-- @param {table} parent - the parent widget
function Mixins:AddTab(parent, list)
  local tabGroup = AceGUI:Create("TabGroup")
  tabGroup:SetLayout("Fill")
  tabGroup:SetTabs({
    { text = list.locale, value = "List" },
    { text = L.IMPORT_TEXT, value = "Import" },
    { text = L.EXPORT_TEXT, value = "Export" }
  })

  tabGroup:SetCallback("OnGroupSelected", function(_, event, group)
    tabGroup:ReleaseChildren()

    local scrollFrame = AceGUI:Create("ScrollFrame")
    scrollFrame:SetLayout("Flow")
    scrollFrame:PauseLayout()

    -- If `self` is UI.Groups.SellInclusions, and `group` is "Import", the below
    -- code is equivalent to: UI.Groups.SellInclusions:Import(scrollFrame, list)
    self[group](self, scrollFrame, list)

    scrollFrame:ResumeLayout()
    scrollFrame:DoLayout()

    tabGroup:AddChild(scrollFrame)
  end)

  tabGroup:SelectTab("List")
  parent:AddChild(tabGroup)
end

-- Creates the UI for the list name tab, which displays a ListFrame widget.
-- @param {table} parent - the parent widget
function Mixins:List(parent, list)
  Widgets:Heading(parent, list.locale)

  -- Help label
  Widgets:Label({
    parent = parent,
    text = list.helpText,
    fullWidth = true
  })

  -- Space
  Widgets:Label({ parent = parent, text = " ", fullWidth = true })

  -- Add/remove help label
  Widgets:Label({
    parent = parent,
    text = L.LIST_ADD_REMOVE_HELP_TEXT,
    fullWidth = true
  })

  -- ListFrame
  Widgets:ListFrame({
    parent = parent,
    -- title = listText,
    list = list
  })

  -- Remove all button
  Widgets:Button({
    parent = parent,
    text = L.REMOVE_ALL_TEXT,
    onClick = function()
      Utils:YesNoPopup({
        text = L.REMOVE_ALL_POPUP:format(list.locale),
        onAccept = function()
          list:RemoveAll()
        end
      })
    end
  })

  -- Sort button
  Widgets:Dropdown({
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
function Mixins:Import(parent, list)
  Widgets:Heading(parent, L.IMPORT_TEXT)
  Widgets:Label({
    parent = parent,
    text = L.IMPORT_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Widgets:MultiLineEditBox({
    parent = parent,
    fullWidth = true,
    numLines = 23
  })

  Widgets:Button({
    parent = parent,
    text = L.IMPORT_TEXT,
    onClick = function()
      for itemID in editBox:GetText():gmatch('([^;]+)') do
        itemID = tonumber(itemID)
        if itemID and (itemID > 0) and (itemID <= Consts.MAX_NUMBER) then
          list:Add(itemID)
        end
      end

      editBox:ClearFocus()
    end
  })
end

-- Creates the UI for the Export tab, which provides an EditBox for output.
-- @param {table} parent - the parent widget
function Mixins:Export(parent, list)
  Widgets:Heading(parent, L.EXPORT_TEXT)
  Widgets:Label({
    parent = parent,
    text = L.EXPORT_HELPER_TEXT,
    fullWidth = true
  })

  local editBox = Widgets:MultiLineEditBox({
    parent = parent,
    fullWidth = true,
    numLines = 23
  })

  Widgets:Button({
    parent = parent,
    text = L.EXPORT_TEXT,
    onClick = function()
      local itemIDs = list:GetItemIDs()
      editBox:SetText(tconcat(itemIDs, ";"))
      editBox:HighlightText(0)
      editBox:SetFocus()
    end
  })
end

-------------------------------------------------------------------------------

-- Add list groups.
for listGroup in Addon.Lists.listGroups() do
  local group = listGroup.uiGroup

  group.parent = "SimpleGroup"
  group.layout = "Fill"
  group.listGroup = listGroup

  -- Add mixins.
  for k, v in pairs(Mixins) do group[k] = v end
end
