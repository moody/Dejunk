-- ListFrame: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Upvalues
local IsAltKeyDown, IsShiftKeyDown = IsAltKeyDown, IsShiftKeyDown

-- Addon
local ListFrame = Addon.Objects.ListFrame
local Colors = Addon.Colors
local ListManager = Addon.ListManager

-- ============================================================================
-- Local Functions
-- ============================================================================

local LIST_FRAME_GENERAL_TOOLTIP = format(
  "%s|n|n%s|n|n%s",
  L.LIST_FRAME_ADD_TOOLTIP,
  L.LIST_FRAME_REM_TOOLTIP,
  L.LIST_FRAME_REM_ALL_TOOLTIP
)

-- Returns the localized text and tooltip for the list.
local function getListStrings(listName)
  local text, tooltip
  
  if (listName == "Inclusions") then
    text, tooltip = L.INCLUSIONS_TEXT, L.INCLUSIONS_TOOLTIP
  elseif (listName == "Exclusions") then
    text, tooltip = L.EXCLUSIONS_TEXT, L.EXCLUSIONS_TOOLTIP
  elseif (listName == "Destroyables") then
    text, tooltip = L.DESTROYABLES_TEXT, L.DESTROYABLES_TOOLTIP
  else
    error(listName.." is not a valid list name.")
  end

  return text, format("%s|n|n%s", tooltip, LIST_FRAME_GENERAL_TOOLTIP)
end

local function createListButton(parent)
  return Addon.Objects.ListButton:Create(parent)
end

-- ============================================================================
-- TitleButton Scripts
-- ============================================================================

local function titleButton_OnClick(self, button)
  if ((button == "RightButton") and IsShiftKeyDown() and IsAltKeyDown()) then
    ListManager:DestroyList(self.ListName)
  end
end

local function titleButton_OnEnter(self)
  DFL.Button.Scripts.OnEnter(self)
  DFL:ShowTooltip(self, DFL.Anchors.TOP, self._label:GetText(), self.Tooltip)
end

local function titleButton_OnLeave(self)
  DFL.Button.Scripts.OnLeave(self)
  DFL:HideTooltip()
end

-- ============================================================================
-- FauxScrollFrame._objFrame Functions
-- ============================================================================

-- Adds the item currently on the cursor to list.
local function addCursorItem(self)
  if self:IsEnabled() and CursorHasItem() then
    local infoType, itemID = GetCursorInfo()

    if (infoType == "item") then
      ListManager:AddToList(self.ListName, itemID)
    end
    
    ClearCursor()
  end
end

-- Removes the item from the list by id.
local function removeItem(self, itemID)
  if self:IsEnabled() then
    ListManager:RemoveFromList(self.ListName, itemID)
  end
end

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame.
-- @param parent - the parent frame
-- @param listName - the name of a ListManager list
function ListFrame:Create(parent, listName)  
  local title, tooltip = getListStrings(listName)

  -- FauxFrame
  local frame = Addon.Objects.FauxFrame:Create(parent, listName, createListButton, 6)

  -- Title button
  local titleButton = frame.TitleButton
  titleButton:SetScript("OnClick", titleButton_OnClick)
  titleButton:SetScript("OnEnter", titleButton_OnEnter)
  titleButton:SetScript("OnLeave", titleButton_OnLeave)
  titleButton:SetColors(Colors.None, Colors.None, Colors[listName], Colors[listName.."Hi"])
  titleButton:SetText(title)
  titleButton.Tooltip = tooltip
  titleButton.ListName = listName

  -- FauxScrollFrame
  local fsFrame = frame.FSFrame
  fsFrame._objFrame:SetScript("OnMouseUp", addCursorItem)
  fsFrame._objFrame.AddCursorItem = addCursorItem
  fsFrame._objFrame.RemoveItem = removeItem
  fsFrame._objFrame.ListName = listName
  fsFrame:SetData(ListManager.Lists[listName])

  return frame
end
