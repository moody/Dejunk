--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_FrameFactory: contains functions that return UIObjects tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Core = DJ.Core
local Colors = DJ.Colors
local Consts = DJ.Consts
local DejunkDB = DJ.DejunkDB
local ListManager = DJ.ListManager
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//  					    			  UI Table Functions
//*******************************************************************
--]]

-- Refreshes a table containing UIObjects created by FrameFactory.
-- @param ui - the table containing UIObjects to be refreshed
function FrameFactory:RefreshUI(ui)
  for k, v in pairs(ui) do v:Refresh() end
end

-- Releases a table containing UIObjects created by FrameFactory.
-- @param ui - the table containing UIObjects to be released
function FrameFactory:ReleaseUI(ui)
  for k, v in pairs(ui) do
    assert(type(v.FF_ObjectType) == "string")

    -- This looks ugly, but it just does this: self:func(v)
    -- So, if the object's type is "Frame", self:ReleaseFrame(v) will be called
    -- I'm doing this to avoid coding a tedious if-elseif based on the object's type
    local func = ("Release"..v.FF_ObjectType)
    self[func](self, v)

    ui[k] = nil
  end
end

--[[
//*******************************************************************
//  					    			    Frame Functions
//*******************************************************************
--]]

-- Creates and returns a frame tailored to Dejunk.
-- @param parent - the parent frame
-- @param color - the color of the frame [optional]
-- @return - a Dejunk frame
function FrameFactory:CreateFrame(parent, color)
  local frame = FramePooler:CreateFrame(parent)
  frame.FF_ObjectType = "Frame"

  -- Refreshes the frame.
  function frame:Refresh()
    if not self.Texture then return end

    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.Color)))
  end

  -- Sets the colors for the frame.
  function frame:SetColors(color)
    self.Color = (color or self.Color or Colors.Black)

    if not self.Texture then
      self.Texture = FramePooler:CreateTexture(self)
    end
  end

  if color then
    frame:SetColors(color)
    frame:Refresh()
  end

  return frame
end

-- Releases a frame created by FrameFactory.
-- @param frame - the frame to release
function FrameFactory:ReleaseFrame(frame)
  -- Objects
  if frame.Texture then
    FramePooler:ReleaseTexture(frame.Texture)
    frame.Texture = nil
  end

  -- Variables
  frame.FF_ObjectType = nil
  frame.Color = nil

  -- Functions
  frame.Refresh = nil
  frame.SetColors = nil

  FramePooler:ReleaseFrame(frame)
end

--[[
//*******************************************************************
//  					    			    Button Functions
//*******************************************************************
--]]

-- Creates and returns a button tailored to Dejunk.
-- @param parent - the parent frame
-- @param font - the font of the button's text
-- @param text - the string to set the button's text
-- @param color - the color of the button [optional]
-- @param colorHi - the color of the button when highlighted [optional]
-- @param textColor - the color of the text [optional]
-- @param textColorHi - the color of the text when highlighted [optional]
-- @return - a Dejunk button
function FrameFactory:CreateButton(parent, font, text, color, colorHi, textColor, textColorHi)
  local button = FramePooler:CreateButton(parent)
  button.FF_ObjectType = "Button"

  button.Texture = FramePooler:CreateTexture(button)

  button.Text = FramePooler:CreateFontString(button, "OVERLAY", font)
  button.Text:SetPoint("CENTER", 1, 0)
  button.Text:SetText(text)

  -- Resizes the button to its minimum required size.
  function button:Resize()
    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  -- Gets the minimum width required by the button to fit its contents.
  function button:GetMinWidth()
    return (self.Text:GetStringWidth() + Tools:Padding())
  end

  -- Gets the minimum height required by the button to fit its contents.
  function button:GetMinHeight()
    return (self.Text:GetStringHeight() + Tools:Padding())
  end

  -- Refreshes the button.
  function button:Refresh()
    if not self:IsEnabled() then
      self:GetScript("OnDisable")(self)
      return
    end

    if (self == GetMouseFocus()) then
      self:GetScript("OnEnter")(self)
    else
      self:GetScript("OnLeave")(self)
    end
  end

  -- Sets the colors for the button.
  function button:SetColors(color, colorHi, textColor, textColorHi)
    self.Color = (color or self.Color or Colors.Button)
    self.ColorHi = (colorHi or self.ColorHi or Colors.ButtonHi)
    self.TextColor = (textColor or self.TextColor or Colors.ButtonText)
    self.TextColorHi = (textColorHi or self.TextColorHi or Colors.ButtonTextHi)
  end

  -- Generic scripts
  button:SetScript("OnEnter", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.ColorHi)))
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColorHi))) end)
	button:SetScript("OnLeave", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(self.Color)))
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColor))) end)

  button:SetScript("OnEnable", function(self) self:Refresh() end)
  button:SetScript("OnDisable", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ButtonDisabled)))
    self.Text:SetTextColor(unpack(Colors:GetColor(Colors.ButtonTextDisabled))) end)

  button:SetColors(color, colorHi, textColor, textColorHi)
  button:Refresh()
  button:Resize()

  return button
end

-- Releases a button created by FrameFactory.
-- @param button - the button to release
function FrameFactory:ReleaseButton(button)
  -- Objects
  FramePooler:ReleaseTexture(button.Texture)
  button.Texture = nil

  FramePooler:ReleaseFontString(button.Text)
  button.Text = nil

  -- Variables
  button.FF_ObjectType = nil
  button.Color = nil
  button.ColorHi = nil
  button.TextColor = nil
  button.TextColorHi = nil

  -- Functions
  button.Resize = nil
  button.GetMinWidth = nil
  button.GetMinHeight = nil
  button.Refresh = nil
  button.SetColors = nil

  FramePooler:ReleaseButton(button)
end

--[[
//*******************************************************************
//  					    			Check Button Functions
//*******************************************************************
--]]

local CheckButtonSizes =
{
  Small =
  {
    Size = 15,
    Font = "GameFontNormalSmall"
  },

  Normal =
  {
    Size = 20,
    Font = "GameFontNormal"
  },

  Huge =
  {
    Size = 30,
    Font = "GameFontNormalHuge"
  }
}

-- Creates and returns a check button tailored to Dejunk.
-- @param parent - the parent frame
-- @param size - the size of the check button
-- @param font - the font of the check button's text
-- @param text - the string to set the check button's text
-- @param textColor - the color of the text [optional]
-- @param tooltip - the body text of the tooltip shown when highlighted [optional]
-- @param svKey - the key of the saved variable associated with the check button [optional]
-- @return - a Dejunk check button
function FrameFactory:CreateCheckButton(parent, size, text, textColor, tooltip, svKey)
  size = (CheckButtonSizes[size] or error("unrecognized check button size"))

  local checkButton = FramePooler:CreateCheckButton(parent)
  checkButton:SetHeight(size.Size)
  checkButton:SetWidth(size.Size)

  checkButton.FF_ObjectType = "CheckButton"

  checkButton.Text = FramePooler:CreateFontString(checkButton, "OVERLAY", size.Font)
  checkButton.Text:SetPoint("LEFT", checkButton, "RIGHT", 0, 0)
  checkButton.Text:SetText(text)

  -- Returns the minimum width of the check button.
  function checkButton:GetMinWidth()
    return (self:GetWidth() + self.Text:GetStringWidth())
  end

  -- Returns the minimum height of the check button.
  function checkButton:GetMinHeight()
    return max(self:GetHeight(), self.Text:GetStringHeight())
  end

  -- Refreshes the check button.
  function checkButton:Refresh()
    -- Colors
    self.Text:SetTextColor(unpack(Colors:GetColor(self.TextColor)))

    -- State
    if self.SVKey then self:SetChecked(DejunkDB.SV[self.SVKey]) end
  end

  -- Sets the colors for the check button.
  function checkButton:SetColors(textColor)
    self.TextColor = (textColor or self.TextColor or Colors.LabelText)
  end

  -- Generic scripts
  if tooltip then
    checkButton:SetScript("OnEnter", function(self)
      Tools:ShowTooltip(self, "ANCHOR_RIGHT", self.Text:GetText(), tooltip) end)
    checkButton:SetScript("OnLeave", function() Tools:HideTooltip() end)
  end

  if svKey then
    checkButton.SVKey = svKey
    checkButton:SetChecked(DejunkDB.SV[svKey])

    checkButton:SetScript("OnClick", function(self)
      DejunkDB.SV[self.SVKey] = self:GetChecked()
    end)
  end

  checkButton:SetColors(textColor)
  checkButton:Refresh()

  return checkButton
end

-- Releases a check button created by FrameFactory.
-- @param checkButton - the check button to release
function FrameFactory:ReleaseCheckButton(checkButton)
  -- Objects
  FramePooler:ReleaseFontString(checkButton.Text)
  checkButton.Text = nil

  -- Variables
  checkButton.FF_ObjectType = nil
  checkButton.SVKey = nil
  checkButton.TextColor = nil

  -- Functions
  checkButton.GetMinWidth = nil
  checkButton.GetMinHeight = nil
  checkButton.Refresh = nil
  checkButton.SetColors = nil

  FramePooler:ReleaseCheckButton(checkButton)
end

--[[
//*******************************************************************
//  					    			    Texture Functions
//*******************************************************************
--]]

-- Creates and returns a texture tailored to Dejunk.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param color - the color of the texture [optional]
-- @return - a Dejunk texture
function FrameFactory:CreateTexture(parent, layer, color)
  local texture = FramePooler:CreateTexture(parent, layer)
  texture.FF_ObjectType = "Texture"

  -- Refreshes the texture.
  function texture:Refresh()
    self:SetColorTexture(unpack(Colors:GetColor(self.Color)))
  end

  -- Sets the colors for the texture.
  function texture:SetColors(color)
    self.Color = (color or Colors.None)
  end

  texture:SetColors(color)
  texture:Refresh()

  return texture
end

-- Releases a texture created by FrameFactory.
-- @param texture - the texture to release
function FrameFactory:ReleaseTexture(texture)
  -- Variables
  texture.FF_ObjectType = nil
  texture.Color = nil

  -- Functions
  texture.Refresh = nil
  texture.SetColors = nil

  FramePooler:ReleaseTexture(texture)
end

--[[
//*******************************************************************
//  					    			 Font String Functions
//*******************************************************************
--]]

-- Returns a font string tailored to Dejunk.
-- @param parent - the parent frame
-- @param layer - the draw layer ("ARTWORK", "BACKGROUND", etc.) [optional]
-- @param font - the font style to inherit [optional]
-- @param color - the color of the font string: {r, g, b[, a]} [optional]
-- @param shadowOffset - the offset of the font string's shadow [optional]
-- @param shadowColor - the color of the font string's shadow [optional]
-- @return - a Dejunk font string
function FrameFactory:CreateFontString(parent, layer, font, color, shadowOffset, shadowColor)
  local fontString = FramePooler:CreateFontString(parent, layer, font, nil, shadowOffset, nil)
  fontString.FF_ObjectType = "FontString"

  -- Refreshes the font string.
  function fontString:Refresh()
    self:SetTextColor(unpack(Colors:GetColor(self.Color)))
    self:SetShadowColor(unpack(Colors:GetColor(self.ShadowColor)))
  end

  -- Sets the colors for the font string.
  function fontString:SetColors(color, shadowColor)
    self.Color = (color or self.Color or Colors.White)
    self.ShadowColor = (shadowColor or self.ShadowColor or Colors.Black)
  end

  fontString:SetColors(color, shadowColor)
  fontString:Refresh()

  return fontString
end

-- Releases a font string created by FrameFactory.
-- @param fontString - the font string to release
function FrameFactory:ReleaseFontString(fontString)
  -- Variables
  fontString.FF_ObjectType = nil
  fontString.Color = nil
  fontString.ShadowColor = nil

  -- Functions
  fontString.Refresh = nil
  fontString.SetColors = nil

  FramePooler:ReleaseFontString(fontString)
end

--[[
//*******************************************************************
//  					    			Scroll Frame Functions
//*******************************************************************
--]]

-- Creates and returns a scroll frame tailored to Dejunk.
-- @param parent - the parent frame
-- @return - a Dejunk scroll frame
function FrameFactory:CreateScrollFrame(parent)
  local scrollFrame = FramePooler:CreateScrollFrame(parent)
  scrollFrame.FF_ObjectType = "ScrollFrame"

  scrollFrame.Texture = FramePooler:CreateTexture(scrollFrame)
  scrollFrame.Offset = 0

  -- Slider
  scrollFrame.Slider = self:CreateSlider(parent)

  -- Refreshes the frame.
  function scrollFrame:Refresh()
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ScrollFrame)))
  end

  scrollFrame:Refresh()

  return scrollFrame
end

-- Releases a scroll frame created by FrameFactory.
-- @param scrollFrame - the scroll frame to release
function FrameFactory:ReleaseScrollFrame(scrollFrame)
  -- Objects
  FramePooler:ReleaseTexture(scrollFrame.Texture)
  scrollFrame.Texture = nil

  self:ReleaseSlider(scrollFrame.Slider)
  scrollFrame.Slider = nil

  -- Variables
  scrollFrame.FF_ObjectType = nil
  scrollFrame.Offset = nil

  FramePooler:ReleaseScrollFrame(scrollFrame)
end

--[[
//*******************************************************************
//  					    			    Slider Functions
//*******************************************************************
--]]

-- Creates and returns a slider tailored to Dejunk.
-- @param parent - the parent frame
-- @return - a Dejunk slider
function FrameFactory:CreateSlider(parent)
  local slider = FramePooler:CreateSlider(parent)
  slider:SetWidth(Consts.SLIDER_DEFAULT_WIDTH)
  slider.FF_ObjectType = "Slider"

  slider.Texture = FramePooler:CreateTexture(slider)

  slider.Thumb = FramePooler:CreateTexture(slider)
  slider.Thumb:SetWidth(Consts.SLIDER_DEFAULT_WIDTH)
  slider.Thumb:SetHeight(Consts.THUMB_DEFAULT_HEIGHT)
  slider:SetThumbTexture(slider.Thumb)

  -- Refreshes the frame.
  function slider:Refresh()
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.Slider)))
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumb)))
  end

  -- Generic scripts
  slider:SetScript("OnMouseDown", function(self)
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumbHi)))
  end)
  slider:SetScript("OnMouseUp", function(self)
    self.Thumb:SetColorTexture(unpack(Colors:GetColor(Colors.SliderThumb)))
  end)

  slider:Refresh()

  return slider
end

-- Releases a slider created by FrameFactory.
-- @param slider - the slider to release
function FrameFactory:ReleaseSlider(slider)
  -- Objects
  FramePooler:ReleaseTexture(slider.Texture)
  slider.Texture = nil

  FramePooler:ReleaseTexture(slider.Thumb)
  slider.Thumb = nil
  slider:SetThumbTexture(nil)

  -- Variables
  slider.FF_ObjectType = nil

  -- Functions
  slider.Refresh = nil

  FramePooler:ReleaseSlider(slider)
end

--[[
//*******************************************************************
//  					    			    EditBox Functions
//*******************************************************************
--]]

-- Creates and returns a frame containing an edit box tailored to Dejunk.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @return - a Dejunk edit box frame
function FrameFactory:CreateEditBoxFrame(parent, font)
  local editBoxFrame = FramePooler:CreateFrame(parent)
  editBoxFrame.FF_ObjectType = "EditBoxFrame"

  editBoxFrame:SetClipsChildren(true)

  editBoxFrame.Texture = self:CreateTexture(editBoxFrame, nil, Colors.Area)

  local editBox = FramePooler:CreateEditBox(editBoxFrame, font)
  editBoxFrame.EditBox = editBox

  editBox:SetPoint("TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
  editBox:SetPoint("BOTTOMRIGHT", -Tools:Padding(0.5), Tools:Padding(0.5))

  editBox:SetScript("OnEscapePressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)
  editBox:SetScript("OnEnterPressed", function(self)
    self:HighlightText(0, 0)
    self:ClearFocus() end)

  function editBoxFrame:Resize()
    local _, fontHeight = editBox:GetFont()
    local newHeight= (fontHeight + Tools:Padding())

    self:SetWidth(Consts.TEXT_FIELD_MIN_WIDTH)
    self:SetHeight(newHeight)
  end

  function editBoxFrame:Refresh()
    self.Texture:Refresh()
    editBox:SetTextColor(unpack(Colors:GetColor(Colors.LabelText)))
  end

  editBoxFrame:Refresh()

  return editBoxFrame
end

-- Releases an edit box frame created by FrameFactory.
-- @param editBoxFrame - the edit box frame to release
function FrameFactory:ReleaseEditBoxFrame(editBoxFrame)
  -- Objects
  self:ReleaseTexture(editBoxFrame.Texture)
  editBoxFrame.Texture = nil

  FramePooler:ReleaseEditBox(editBoxFrame.EditBox)
  editBoxFrame.EditBox = nil

  -- Variables
  editBoxFrame.FF_ObjectType = nil

  -- Functions
  editBoxFrame.Resize = nil
  editBoxFrame.Refresh = nil

  FramePooler:ReleaseFrame(editBoxFrame)
end

--[[
//*******************************************************************
//  					    			    TextField Functions
//*******************************************************************
--]]

-- Creates and returns a frame containing an edit box frame with an above label text,
-- and a below helper text.
-- @param parent - the parent frame
-- @param font - the font style for the edit box to inherit [optional]
-- @return - a Dejunk text field
function FrameFactory:CreateTextField(parent, font)
  local textField = FramePooler:CreateFrame(parent)
  textField.FF_ObjectType = "TextField"

  textField.LabelFontString = self:CreateFontString(textField, nil, "GameFontNormal", Colors.LabelText)
  textField.LabelFontString:SetPoint("TOPLEFT")

  local editBoxFrame = self:CreateEditBoxFrame(textField, font)
  textField.EditBoxFrame = editBoxFrame
  editBoxFrame:SetPoint("LEFT")
  editBoxFrame:SetPoint("RIGHT")

  textField.HelperFontString = self:CreateFontString(textField, nil, "GameFontNormalSmall", Colors.LabelText)
  textField.HelperFontString:SetPoint("BOTTOMLEFT")

  function textField:SetLabelText(labelText)
    self.LabelFontString:SetText(labelText)
  end

  function textField:SetHelperText(helperText)
    self.HelperFontString:SetText(helperText)
  end

  function textField:Resize()
    editBoxFrame:Resize()

    local newWidth = max(self.LabelFontString:GetWidth(), self.HelperFontString:GetWidth())
    newWidth = max(newWidth, editBoxFrame:GetWidth())

    local newHeight= (self.LabelFontString:GetHeight() + Tools:Padding(0.5))
    newHeight = (newHeight + editBoxFrame:GetHeight() + Tools:Padding(0.5))
    newHeight = (newHeight + self.HelperFontString:GetHeight())

    self:SetWidth(newWidth)
    self:SetHeight(newHeight)
  end

  function textField:Refresh()
    self.LabelFontString:Refresh()
    editBoxFrame:Refresh()
    self.HelperFontString:Refresh()
  end

  textField:Refresh()

  return textField
end

-- Releases a text field created by FrameFactory.
-- @param textField - the text field to release
function FrameFactory:ReleaseTextField(textField)
  -- Objects
  self:ReleaseFontString(textField.LabelFontString)
  textField.LabelFontString = nil

  self:ReleaseFontString(textField.HelperFontString)
  textField.HelperFontString = nil

  self:ReleaseEditBoxFrame(textField.EditBoxFrame)
  textField.EditBoxFrame = nil

  -- Variables
  textField.FF_ObjectType = nil

  -- Functions
  textField.SetLabelText = nil
  textField.SetHelperText = nil
  textField.Resize = nil
  textField.Refresh = nil

  FramePooler:ReleaseFrame(textField)
end

--[[
//*******************************************************************
//  					    			  List Frame Functions
//*******************************************************************
--]]

-- Creates and returns a list frame for displaying data from a list of items.
-- @param parent - the parent frame
-- @param listName - the name of a list defined in ListManager
-- @param buttonCount - the number of buttons (items) to display
-- @param title - the title of the list frame
-- @param titleColor - the color of the title
-- @param titleColorHi - the color of the title when highlighted
-- @param tooltip - the tooltip to display when highlighting the title
-- @return - a Dejunk list frame
function FrameFactory:CreateListFrame(parent, listName, buttonCount, title, titleColor, titleColorHi, tooltip)
  assert(ListManager[listName] ~= nil)

  local listFrame = self:CreateFrame(parent)
  listFrame.FF_ObjectType = "ListFrame"
  listFrame.ItemList = ListManager.Lists[listName]

  local scrollFrame = self:CreateScrollFrame(listFrame)
  local slider = scrollFrame.Slider
  listFrame.ScrollFrame = scrollFrame

  local titleButton = self:CreateButton(listFrame, "GameFontNormalHuge", title,
    Colors.None, Colors.None, titleColor, titleColorHi)
  listFrame.TitleButton = titleButton

  local importButton = self:CreateButton(listFrame, "GameFontNormalSmall", L.IMPORT_TEXT)
  listFrame.ImportButton = importButton
  local exportButton = self:CreateButton(listFrame, "GameFontNormalSmall", L.EXPORT_TEXT)
  listFrame.ExportButton = exportButton

  -- Initialize points
  titleButton:SetPoint("TOP", listFrame)

  importButton:SetPoint("BOTTOMLEFT", listFrame)
  importButton:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOM", -Tools:Padding(0.25), 0)

  exportButton:SetPoint("BOTTOMRIGHT", listFrame)
  exportButton:SetPoint("BOTTOMLEFT", listFrame, "BOTTOM", Tools:Padding(0.25), 0)

  slider:SetPoint("BOTTOMRIGHT", exportButton, "TOPRIGHT", 0, Tools:Padding(0.5))
  scrollFrame:SetPoint("BOTTOMLEFT", importButton, "TOPLEFT", 0, Tools:Padding(0.5))
  scrollFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)

  -- Title button
  titleButton:RegisterForClicks("RightButtonUp")
  titleButton:SetScript("OnClick", function(self, button, down)
    if ((button == "RightButton") and IsShiftKeyDown() and IsAltKeyDown()) then
      ListManager:DestroyList(listName) end
  end)
  titleButton:HookScript("OnEnter", function(self)
    Tools:ShowTooltip(self, "ANCHOR_TOP", self.Text:GetText(), tooltip) end)
  titleButton:HookScript("OnLeave", function(self)
    Tools:HideTooltip() end)

  -- Import button
  importButton:SetScript("OnClick", function(self, button, down)
    Core:ShowTransportChild(listName, DJ.TransportChildFrame.Import) end)

  -- Export button
  exportButton:SetScript("OnClick", function(self, button, down)
    Core:ShowTransportChild(listName, DJ.TransportChildFrame.Export) end)

  -- Slider
  slider:SetMinMaxValues(0, 0)
  slider:SetValueStep(1)
  slider:SetValue(0)

  slider:SetScript("OnValueChanged", function(self, value)
    -- Clamp scroll value to min/max
    local minVal, maxVal = self:GetMinMaxValues()
    value = Clamp(value, minVal, maxVal)

    self:SetValue(value)

    scrollFrame.Offset = floor(value + 0.5)
  end)

  -- Scroll frame
  scrollFrame.Buttons = {}
  for i = 1, buttonCount do
    local button = self:CreateListButton(scrollFrame, listName)
    button:SetHeight(Consts.LIST_BUTTON_HEIGHT)

    if i == 1 then
      button:SetPoint("TOPLEFT", Tools:Padding(0.5), -Tools:Padding(0.5))
      button:SetPoint("TOPRIGHT", -Tools:Padding(0.5), -Tools:Padding(0.5))
    else
      button:SetPoint("TOPLEFT", scrollFrame.Buttons[i-1], "BOTTOMLEFT", 0, -Tools:Padding(0.5))
      button:SetPoint("TOPRIGHT", scrollFrame.Buttons[i-1], "BOTTOMRIGHT", 0, -Tools:Padding(0.5))
    end

    scrollFrame.Buttons[i] = button
  end

  -- Drops the item on the cursor into the scroll frame.
  function scrollFrame:DropItem()
    if CursorHasItem() then
      local infoType, itemID = GetCursorInfo()

      if infoType == "item" then
        ListManager:AddToList(listName, itemID)
      end

      ClearCursor()
    end
  end

  scrollFrame:SetScript("OnMouseUp", scrollFrame.DropItem)

  -- Displays the slider.
  function listFrame:ShowSlider()
    scrollFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)
    slider:Show()
  end

  -- Hides the slider.
  function listFrame:HideSlider()
    scrollFrame:SetPoint("BOTTOMRIGHT", exportButton, "TOPRIGHT", 0, Tools:Padding(0.5))
    slider:Hide()
  end

  -- Updates the buttons in the scroll frame.
  function listFrame:Update()
    if (#self.ItemList > 0) and (not ListManager:IsParsing(listName)) then
      exportButton:SetEnabled(true)
    else
      exportButton:SetEnabled(false)
    end

    -- Update buttons
    for i, button in ipairs(scrollFrame.Buttons) do
      local index = (i + scrollFrame.Offset)
      local item = self.ItemList[index]

      if item then
        button:Show()
        button:SetItem(item)
      else
        button:Hide()
      end
    end

    -- Update slider max value
    local maxVal = (#self.ItemList - #scrollFrame.Buttons)
    if maxVal > 0 then
      self:ShowSlider()
      slider:SetMinMaxValues(0, maxVal)
    else
      self:HideSlider()
      slider:SetMinMaxValues(0, 0)
    end
  end

  -- Resizes the frame to its minimum required size.
  function listFrame:Resize()
    titleButton:Resize()
    importButton:Resize()
    exportButton:Resize()

    local sfHeight = ((#scrollFrame.Buttons * Consts.LIST_BUTTON_HEIGHT) +
      ((#scrollFrame.Buttons + 1) * Tools:Padding(0.5)))
    scrollFrame:SetHeight(sfHeight)
    slider:SetHeight(sfHeight)

    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  -- Gets the minimum width required by the frame to fit its contents.
  function listFrame:GetMinWidth()
    local titleWidth = (self.TitleButton:GetWidth() + Tools:Padding(2))

    local transportWidth = max(importButton:GetMinWidth(), exportButton:GetMinWidth())
    transportWidth = ((transportWidth * 2) + Tools:Padding(0.5))

    local width = max(titleWidth, transportWidth)

    return max(width, Consts.LIST_FRAME_MIN_WIDTH)
  end

  -- Gets the minimum height required by the frame to fit its contents.
  function listFrame:GetMinHeight()
    local sfHeight = ((#scrollFrame.Buttons * Consts.LIST_BUTTON_HEIGHT) +
                     ((#scrollFrame.Buttons + 1) * Tools:Padding(0.5)))

    local transportHeight = (max(importButton:GetMinHeight(),
      exportButton:GetMinHeight()) + Tools:Padding(0.5))

    return (titleButton:GetHeight() + sfHeight + transportHeight)
  end

  -- Refreshes the frame
  function listFrame:Refresh()
    titleButton:Refresh()
    importButton:Refresh()
    exportButton:Refresh()
    scrollFrame:Refresh()
    slider:Refresh()

    for i, button in ipairs(scrollFrame.Buttons) do
      button:Refresh()
    end
  end

  -- Scripts
  listFrame:SetScript("OnUpdate", listFrame.Update)
  listFrame:SetScript("OnMouseWheel", function(self, delta)
    slider:SetValue(slider:GetValue() - delta) end)

  listFrame:Refresh()
  listFrame:Update()

  return listFrame
end

-- Releases a list frame created by FrameFactory.
-- @param listFrame - the list frame to release
function FrameFactory:ReleaseListFrame(listFrame)
  -- Objects
  self:ReleaseButton(listFrame.TitleButton)
  listFrame.TitleButton = nil

  self:ReleaseButton(listFrame.ImportButton)
  listFrame.ImportButton = nil

  self:ReleaseButton(listFrame.ExportButton)
  listFrame.ExportButton = nil

  for i, button in pairs(listFrame.ScrollFrame.Buttons) do
    self:ReleaseListButton(button) end
  listFrame.ScrollFrame.Buttons = nil

  self:ReleaseScrollFrame(listFrame.ScrollFrame)
  listFrame.ScrollFrame.DropItem = nil
  listFrame.ScrollFrame = nil

  -- Variables
  listFrame.FF_ObjectType = nil
  listFrame.ItemList = nil

  -- Functions
  listFrame.ShowSlider = nil
  listFrame.HideSlider = nil
  listFrame.Update = nil
  listFrame.GetMinWidth = nil
  listFrame.GetMinHeight = nil
  listFrame.Resize = nil
  listFrame.Refresh = nil

  self:ReleaseFrame(listFrame)
end

--[[
//*******************************************************************
//  					    	     List Button Functions
//*******************************************************************
--]]

-- Creates and returns a button to be displayed in a list frame.
-- @param parent - the parent frame
-- @param listName - the name of a list defined in ListManager
-- @return - a Dejunk list button
function FrameFactory:CreateListButton(parent, listName)
  assert(parent.FF_ObjectType == "ScrollFrame", "ListButton parent must be a ScrollFrame")
  assert(ListManager[listName] ~= nil)

  local button = FramePooler:CreateButton(parent)
  button:SetHeight(Consts.LIST_BUTTON_HEIGHT)
  button.FF_ObjectType = "ListButton"

  button.Texture = FramePooler:CreateTexture(button)
  button.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ListButton)))

  button.Icon = FramePooler:CreateTexture(button, "ARTWORK")
  button.Icon:ClearAllPoints()
  button.Icon:SetPoint("LEFT", Tools:Padding(0.5), 0)
  button.Icon:SetWidth(Consts.LIST_BUTTON_ICON_SIZE)
  button.Icon:SetHeight(Consts.LIST_BUTTON_ICON_SIZE)

  button.Text = FramePooler:CreateFontString(button, "OVERLAY", "GameFontNormal")
  button.Text:SetPoint("LEFT", button.Icon, "RIGHT", Tools:Padding(0.5), 0)
  button.Text:SetPoint("RIGHT", -Tools:Padding(0.5), 0)
  button.Text:SetWordWrap(false)
  button.Text:SetJustifyH("LEFT")

  -- Sets the item data to be displayed.
  function button:SetItem(item)
    self.Item = item
    self:Refresh()
  end

  -- Refreshes the frame.
  function button:Refresh()
    if not self.Item then self:Hide() return end

    -- Texture
    if (self == GetMouseFocus()) then
      self:GetScript("OnEnter")(self)
    else
      -- OnLeave hides the current tooltip, so we don't call it
      self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ListButton)))
    end

    -- Data
    self.Icon:SetTexture(self.Item.Texture)
    self.Text:SetText(format("[%s]", self.Item.Name))
    self.Text:SetTextColor(unpack(Colors:GetColorByQuality(self.Item.Quality)))
  end

  -- Scripts
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:SetScript("OnClick", function(self, button, down)
    if (button == "LeftButton") then
      if IsControlKeyDown() then
        DressUpVisual(self.Item.Link) -- FrameXML/DressUpFrames.lua
      else
        parent:DropItem()
      end
    elseif (button == "RightButton") then
      ListManager:RemoveFromList(listName, self.Item.ItemID)
    end
  end)

  button:SetScript("OnEnter", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ListButtonHi)))
    Tools:ShowItemTooltip(self, "ANCHOR_TOP", button.Item.Link) end)
  button:SetScript("OnLeave", function(self)
    self.Texture:SetColorTexture(unpack(Colors:GetColor(Colors.ListButton)))
    Tools:HideTooltip() end)

  button:Refresh()

  return button
end

-- Releases a list button created by FrameFactory.
-- @param button - the list button to release
function FrameFactory:ReleaseListButton(button)
  -- Objects
  FramePooler:ReleaseTexture(button.Texture)
  button.Texture = nil

  FramePooler:ReleaseTexture(button.Icon)
  button.Icon = nil

  FramePooler:ReleaseFontString(button.Text)
  button.Text = nil

  -- Variables
  button.FF_ObjectType = nil
  button.Item = nil

  -- Functions
  button.SetItem = nil
  button.Refresh = nil

  FramePooler:ReleaseButton(button)
end
