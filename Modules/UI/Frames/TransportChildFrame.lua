-- TransportChildFrame: provides an interface for importing or exporting list and profile data.

local AddonName, Addon = ...

-- Libs
local AceSerializer = LibStub("AceSerializer-3.0")
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local assert, format, strtrim = assert, format, strtrim

local StaticPopup_Show, ChatEdit_FocusActiveWindow =
      StaticPopup_Show, ChatEdit_FocusActiveWindow

-- Modules
local TransportChildFrame = Addon.Frames.TransportChildFrame
local Colors = Addon.Colors
local Core = Addon.Core
local DB = Addon.DB
local ListManager = Addon.ListManager
local Tools = Addon.Tools
local ParentFrame = Addon.Frames.ParentFrame
local ProfileChildFrame = Addon.Frames.ProfileChildFrame

-- Variables
local types = {
  IMPORT = "IMPORT",
  EXPORT = "EXPORT"
}

local importTable = nil

-- ============================================================================
-- Popup
-- ============================================================================

do
  local function importProfile(key)
    if DB:ProfileExists(key) then
      Core:Print(format(L.PROFILE_EXISTS_TEXT, DCL:ColorString(key, Colors.Destroyables)))
    elseif DB:CreateProfile(key, importTable) then
      DB:SetProfile(key)
      ListManager:Update()
      ParentFrame:SetContent(ProfileChildFrame)
      Core:Print(format(L.PROFILE_ACTIVATED_TEXT, DCL:ColorString(key, Colors.Exclusions)))
    end
  end
  
  StaticPopupDialogs["DEJUNK_IMPORT_PROFILE_POPUP"] = {
    text = L.PROFILE_CREATE_POPUP,
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 24,
    OnAccept = function(self)
      local text = strtrim(self.editBox:GetText())
      if (#text > 0) then importProfile(text) end
    end,
    EditBoxOnEnterPressed = function(self)
      local text = strtrim(self:GetParent().editBox:GetText())
      if (#text > 0) then importProfile(text) end
      self:GetParent():Hide()
    end,
    OnShow = function(self)
      self.editBox:SetFocus()
    end,
    OnHide = function(self)
      ChatEdit_FocusActiveWindow()
      self.editBox:SetText("")
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
  }
end

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function TransportChildFrame:OnInitialize()
  local frame = self.Frame
  frame:SetAlignment(DFL.Alignments.CENTER)
  frame:SetDirection(DFL.Directions.DOWN)
  frame:SetMinHeight(300)
  frame:SetLayout(DFL.Layouts.FLEX)
  frame:SetSpacing(DFL:Padding())
  
  self:CreateUI()
  self.CreateUI = nil
end

-- ============================================================================
-- UI Functions
-- ============================================================================

function TransportChildFrame:CreateUI()
  local frame = self.Frame

  -- Title (list name)
  local title = DFL.FontString:Create(frame, nil, DFL.Fonts.Huge)
  title:SetColors(Colors.LabelText)
  self.TitleFontString = title
  frame:Add(title)

  do -- Text field
    local f = DFL.Frame:Create(frame, DFL.Alignments.LEFT, DFL.Directions.DOWN)
    f:SetSpacing(DFL:Padding(0.5))
    frame:Add(f)

    -- Label text (import/export)
    local label = DFL.FontString:Create(f)
    label:SetColors(Colors.LabelText)
    self.LabelFontString = label
    f:Add(label)
    
    -- Text area
    local textArea = DFL.TextArea:Create(f)
    textArea:SetMinWidth(445)
    textArea:SetMinHeight(275)
    textArea:SetColors(Colors.LabelText, Colors.ScrollFrame, Colors.SliderColors)
    self.TextArea = textArea
    -- Keep width of text area the same size as f
    function f:OnSetWidth(width)
      if (width > textArea:GetWidth()) then
        textArea:SetWidth(width)
      end
    end
    f:Add(textArea)

    -- Helper text
    local helper = DFL.FontString:Create(f, nil, DFL.Fonts.Small)
    helper:SetColors(Colors.LabelText)
    self.HelperFontString = helper
    f:Add(helper)
  end

  do -- Buttons
    local f = DFL.Frame:Create(frame)
    f:SetLayout(DFL.Layouts.FILL)
    f:SetSpacing(DFL:Padding(0.25))
    frame:Add(f)

    -- Left button
    local leftButton = DFL.Button:Create(f, nil, DFL.Fonts.Small)
    leftButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
    self.LeftButton = leftButton
    f:Add(leftButton)

    -- Right button
    local rightButton = DFL.Button:Create(f, L.BACK_TEXT, DFL.Fonts.Small)
    function rightButton:OnClick() ParentFrame:SetContent(self.PreviousFrame) end
    rightButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
    rightButton.SetEnabled = nop
    self.RightButton = rightButton
    f:Add(rightButton)
  end
end

-- ============================================================================
-- SetData()
-- ============================================================================

local function setListData(self, listName, type)
  local titleText = self.TitleFontString

  local labelText = self.LabelFontString
  local editBox = self.TextArea._editBox
  local helperText = self.HelperFontString
  local leftButton = self.LeftButton
  self.RightButton.PreviousFrame = Addon.Frames.DejunkChildFrame

  if (type == types.IMPORT) then
    titleText:SetText(format(L.IMPORT_TITLE_TEXT, Tools:GetColoredListName(listName)))
    labelText:SetText(L.IMPORT_LABEL_TEXT)
    helperText:SetText(L.IMPORT_HELPER_TEXT)

    editBox:SetText("")
    editBox:SetFocus()

    leftButton:SetText(L.IMPORT_TEXT)
    leftButton:SetScript("OnClick", function(self, button, down)
      ListManager:ImportToList(listName, editBox:GetText())
      editBox:ClearFocus()
    end)
  else -- Export
    local function exportData()
      editBox:SetText(ListManager:ExportFromList(listName))
      editBox:SetFocus()
      editBox:SetCursorPosition(0)
      editBox:HighlightText()
    end

    exportData()

    titleText:SetText(format(L.EXPORT_TITLE_TEXT, Tools:GetColoredListName(listName)))
    labelText:SetText(L.EXPORT_LABEL_TEXT)
    helperText:SetText(L.EXPORT_HELPER_TEXT)

    leftButton:SetText(L.EXPORT_TEXT)
    leftButton:SetScript("OnClick", exportData)
  end
end

local function setProfileData(self, type)
  local titleText = self.TitleFontString

  local labelText = self.LabelFontString
  local editBox = self.TextArea._editBox
  local helperText = self.HelperFontString
  local leftButton = self.LeftButton
  self.RightButton.PreviousFrame = ProfileChildFrame

  if (type == types.IMPORT) then
    titleText:SetText(L.IMPORT_PROFILE_TEXT)
    labelText:SetText(L.IMPORT_LABEL_TEXT)
    helperText:SetText(L.IMPORT_PROFILE_HELPER_TEXT)

    editBox:SetText("")
    editBox:SetFocus()

    leftButton:SetText(L.IMPORT_TEXT)
    leftButton:SetScript("OnClick", function(self, button, down)
      local status, profile = AceSerializer:Deserialize(editBox:GetText())
      if status and profile then
        StaticPopup_Show("DEJUNK_IMPORT_PROFILE_POPUP")
        importTable = profile
      else
        Core:Print(L.PROFILE_IMPORT_FAILED_TEXT)
      end
      editBox:ClearFocus()
    end)
  else -- Export
    local function exportData()
      editBox:SetText(AceSerializer:Serialize(DB.Profile))
      editBox:SetFocus()
      editBox:SetCursorPosition(0)
      editBox:HighlightText()
    end

    exportData()

    titleText:SetText(L.EXPORT_PROFILE_TEXT)
    labelText:SetText(L.EXPORT_LABEL_TEXT)
    helperText:SetText(L.EXPORT_HELPER_TEXT)

    leftButton:SetText(L.EXPORT_TEXT)
    leftButton:SetScript("OnClick", exportData)
  end
end

-- Sets the list and transport type for the frame.
-- @param listName - the name of the list used for transport operations
-- @param type - the type of transport operations to perform
function TransportChildFrame:SetData(listName, type)
  assert(types[type])
  assert(ListManager.Lists[listName] or (listName == "Profiles"))

  if (listName == "Profiles") then
    setProfileData(self, type)
  else
    setListData(self, listName, type)
  end
end
