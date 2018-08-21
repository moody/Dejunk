-- TransportChildFrame: provides an interface for importing or exporting list data.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Modules
local TransportChildFrame = Addon.Frames.TransportChildFrame

local Colors = Addon.Colors
local ListManager = Addon.ListManager
local Tools = Addon.Tools

-- Variables
local types = {
  IMPORT = "IMPORT",
  EXPORT = "EXPORT"
}

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
    function rightButton:OnClick()
      Addon.Frames.ParentFrame:SetContent(Addon.Frames.DejunkChildFrame)
    end
    rightButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
    rightButton.SetEnabled = nop
    f:Add(rightButton)
  end
end

-- ============================================================================
--                           Getters and Setters
-- ============================================================================

-- Sets the list and transport type for the frame.
-- @param listName - the name of the list used for transport operations
-- @param type - the type of transport operations to perform
function TransportChildFrame:SetData(listName, type)
  assert(types[type])
  assert(ListManager.Lists[listName])
  
  local titleText = self.TitleFontString

  local labelText = self.LabelFontString
  local editBox = self.TextArea._editBox
  local helperText = self.HelperFontString
  local leftButton = self.LeftButton

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
