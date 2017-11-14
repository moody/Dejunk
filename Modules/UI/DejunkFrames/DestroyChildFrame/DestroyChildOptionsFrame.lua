-- DestroyChildOptionsFrame: displays a simple options menu.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DestroyChildOptionsFrame = DJ.DejunkFrames.DestroyChildOptionsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local FrameFactory = DJ.FrameFactory

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function DestroyChildOptionsFrame:OnInitialize()
  self:CreateOptions()
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function DestroyChildOptionsFrame:Resize()
  local ui = self.UI

  ui.StartDestroyingButton:Resize()
  ui.SettingsFrame:Resize()

  local newWidth = max(ui.StartDestroyingButton:GetWidth(), ui.SettingsFrame:GetWidth())
  ui.StartDestroyingButton:SetWidth(newWidth)
  ui.SettingsFrame:SetWidth(newWidth)

  local newHeight = ui.SettingsFrame:GetMinHeight() +
    Tools:Padding(0.5) + ui.StartDestroyingButton:GetHeight()

  self:SetWidth(newWidth + Tools:Padding(2))
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetHeight
  local setHeight = DestroyChildOptionsFrame.SetHeight

  function DestroyChildOptionsFrame:SetHeight(height)
    local oldHeight = self:GetHeight()
    setHeight(self, height)

    -- Update SettingsFrame's minimum scroll frame height
    height = height - self.UI.StartDestroyingButton:GetHeight() -
      Tools:Padding(0.5) - self.UI.SettingsFrame.TitleButton:GetHeight()
    self.UI.SettingsFrame.ScrollFrame:SetMinHeight(height)
  end
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

function DestroyChildOptionsFrame:CreateOptions()
  local ui = self.UI
  local frame = self.Frame

  -- Start Destroying button
  ui.StartDestroyingButton = FrameFactory:CreateButton(frame, "GameFontNormalSmall", "Start Destroying (L)")
  ui.StartDestroyingButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", Tools:Padding(), 0)
  ui.StartDestroyingButton:SetScript("OnUpdate", function(self, button, down)
    self:SetEnabled(DJ.Core:CanDestroy()) end)
  ui.StartDestroyingButton:SetScript("OnClick", function(self, button, down)
    DJ.Destroyer:StartDestroying()
  end)

  -- Scrolling options frame
  ui.SettingsFrame = FrameFactory:CreateScrollingOptionsFrame(frame, "Options (L)", "GameFontNormalHuge")
  ui.SettingsFrame:SetPoint("TOPLEFT", frame, Tools:Padding(), 0)

  local add = function(option)
    self.UI.SettingsFrame:AddOption(option)
  end

  -- General heading
  local generalHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  generalHeading:SetText(L.GENERAL_TEXT..":")
  add(generalHeading)

  -- Auto destroy
  local text = "Auto Destroy (L)"
  local tip = "Automatically begin destroying items when less than 5 empty bag slots remain. (L)"
  add(FrameFactory:CreateCheckButton(nil, "Small", text, nil, tip, DejunkDB.AutoDestroy))

  -- Price threshold check button and currency input
  add(FrameFactory:CreateCheckButton(nil, "Small", "Price Threshold (L)", nil,
    "Only destroy items or stacks of items worth less than a set price. (L)", DejunkDB.DestroyUsePriceThreshold))
  add(FrameFactory:CreateCurrencyInputFrame(nil, "GameFontNormalSmall", DejunkDB.DestroyPriceThreshold))

  -- Destroy heading
  local destroyHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  destroyHeading:SetText(L.DESTROY_TEXT..":")
  add(destroyHeading)

  -- Destroy poor
  local dAllTtip = "Destroy all items of this quality. (L)"
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.POOR_TEXT, Colors.Poor, dAllTtip, DejunkDB.DestroyPoor))

  -- Destroy Inclusions Items
  local inclusionsText = Tools:GetColorString(L.INCLUSIONS_TEXT, Colors.DefaultColors.Inclusions)
  add(FrameFactory:CreateCheckButton(nil, "Small", inclusionsText, nil,
    "Destroy items on the Inclusions list. (L)", DejunkDB.DestroyInclusions))

  -- Ignore heading
  local ignoreHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  ignoreHeading:SetText(L.IGNORE_TEXT..":")
  add(ignoreHeading)

  -- Ignore Exclusions Items
  local ignoreExclusionsText = Tools:GetColorString(L.EXCLUSIONS_TEXT, Colors.DefaultColors.Exclusions)
  add(FrameFactory:CreateCheckButton(nil, "Small", ignoreExclusionsText, nil,
    "Ignore items on the Exclusions list. (L)", DejunkDB.DestroyIgnoreExclusions))
end
