-- Dejunk_CheckButton: contains FrameFactory functions to create a check button tailored to Dejunk.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local DejunkDB = DJ.DejunkDB
local Tools = DJ.Tools
local FrameCreator = DJ.FrameCreator

-- Variables
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

--[[
//*******************************************************************
//  					    			Check Button Functions
//*******************************************************************
--]]

-- Creates and returns a check button tailored to Dejunk.
-- @param parent - the parent frame
-- @param size - the size of the check button
-- @param font - the font of the check button's text
-- @param text - the string to set the check button's text
-- @param textColor - the color of the text [optional]
-- @param tooltip - the body text of the tooltip shown when highlighted [optional]
-- @param svKey - the key of the saved variable associated with the check button [optional]
-- @return - a Dejunk check button
function FrameFactory:CreateCheckButton(parent, size, text, textColor, tooltip, svKey, onClickCallBack)
  size = (CheckButtonSizes[size] or error("Unrecognized check button size"))

  local checkButton = FrameCreator:CreateCheckButton(parent)
  checkButton:SetHeight(size.Size)
  checkButton:SetWidth(size.Size)

  checkButton.FF_ObjectType = "CheckButton"

  checkButton.Text = FrameCreator:CreateFontString(checkButton, "OVERLAY", size.Font)
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
    self:Refresh()
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
      if onClickCallBack then onClickCallBack() end
    end)
  end

  checkButton:SetColors(textColor)

  return checkButton
end
