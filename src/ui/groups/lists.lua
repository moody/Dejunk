local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Consts = Addon.Consts
local DB = Addon.DB
local GetCoinTextureString = _G.GetCoinTextureString
local L = Addon.Libs.L
local Lists = Addon.Lists
local tconcat = table.concat
local Tools = Addon.Tools
local Utils = Addon.UI.Utils

local LIST_NAME_TO_TEXT = {
  Inclusions = L.INCLUSIONS_TEXT,
  Exclusions = L.EXCLUSIONS_TEXT,
  Destroyables = L.DESTROYABLES_TEXT
}

local function getListHelpText(listName)
  if listName == "Inclusions" then
    return L.INCLUSIONS_HELP_TEXT
  elseif listName == "Exclusions" then
    return L.EXCLUSIONS_HELP_TEXT
  elseif listName == "Destroyables" then
    if DB.Profile.DestroyBelowPrice.Enabled then
      return L.DESTROYABLES_HELP_BELOW_PRICE_TEXT:format(
        GetCoinTextureString(DB.Profile.DestroyBelowPrice.Value)
      )
    end

    return L.DESTROYABLES_HELP_TEXT
  end
end

local function getCreateFunc(listName)
  local listText = LIST_NAME_TO_TEXT[listName]

  return function(list, parent)
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
      { text = listText, value = "List" },
      { text = L.IMPORT_TEXT, value = "Import" },
      { text = L.EXPORT_TEXT, value = "Export" }
    })

    tabGroup:SetCallback("OnGroupSelected", function(self, event, group)
      self:ReleaseChildren()

      local scrollFrame = AceGUI:Create("ScrollFrame")
      scrollFrame:SetLayout("Flow")
      scrollFrame:PauseLayout()

      --[[
        If `list` is UI.Groups.Inclusions, and `group` is "Import", the below
        code is equivalent to calling: UI.Groups.Inclusions:Import(scrollFrame)
      ]]
      list[group](list, scrollFrame)

      scrollFrame:ResumeLayout()
      scrollFrame:DoLayout()

      self:AddChild(scrollFrame)
    end)

    tabGroup:SelectTab("List")
    parent:AddChild(tabGroup)
  end
end

local function getListFunc(listName)
  local listText = LIST_NAME_TO_TEXT[listName]
  local removeAll = function() Lists[listName]:RemoveAll() end

  return function(list, parent)
    Utils:Heading(parent, listText)

    -- Help label
    Utils:Label({
      parent = parent,
      text = getListHelpText(listName),
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
      list = Lists[listName]
    })

    -- Remove all button
    Utils:Button({
      parent = parent,
      text = L.REMOVE_ALL_TEXT,
      onClick = function()
        Tools:YesNoPopup({
          text = L.REMOVE_ALL_POPUP:format(Lists[listName].localeColored),
          onAccept = removeAll
        })
      end
    })
  end
end

local function getImportFunc(listName)
  return function(list, parent)
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
            Lists[listName]:Add(itemID)
          end
        end

        editBox:ClearFocus()
      end
    })
  end
end

local function getExportFunc(listName)
  return function(list, parent)
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
        local itemIDs = Lists[listName]:GetItemIDs()
        editBox:SetText(tconcat(itemIDs, ";"))
        editBox:HighlightText(0)
        editBox:SetFocus()
      end
    })
  end
end

-- Add list groups
for listName in pairs(LIST_NAME_TO_TEXT) do
  local list = Addon.UI.Groups[listName] or error("Unsupported group: " .. listName)

  list.parent = "SimpleGroup"
  list.layout = "Fill"

  list.Create = getCreateFunc(listName)
  list.List = getListFunc(listName)
  list.Import = getImportFunc(listName)
  list.Export = getExportFunc(listName)
end
