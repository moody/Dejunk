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
  ui.StartDestroyingButton = FrameFactory:CreateButton(frame, "GameFontNormalSmall", L.START_DESTROYING_BUTTON_TEXT)
  ui.StartDestroyingButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", Tools:Padding(), 0)
  ui.StartDestroyingButton:SetScript("OnUpdate", function(self, button, down)
    self:SetEnabled(DJ.Core:CanDestroy()) end)
  ui.StartDestroyingButton:SetScript("OnClick", function(self, button, down)
    DJ.Destroyer:StartDestroying()
  end)

  -- Scrolling options frame
  ui.SettingsFrame = FrameFactory:CreateScrollingOptionsFrame(frame, L.OPTIONS_TEXT, "GameFontNormalHuge")
  ui.SettingsFrame:SetPoint("TOPLEFT", frame, Tools:Padding(), 0)

  local add = function(option)
    self.UI.SettingsFrame:AddOption(option)
  end

  -- Callback function for check buttons, queues up auto destroy
  local cbCallback = DJ.Destroyer.QueueAutoDestroy

  -- General heading
  local generalHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  generalHeading:SetText(L.GENERAL_TEXT..":")
  add(generalHeading)

  -- Auto destroy
  add(FrameFactory:CreateCheckButton(nil, "Small", L.AUTO_DESTROY_TEXT, nil,
    L.AUTO_DESTROY_TOOLTIP, DejunkDB.AutoDestroy, cbCallback))

  -- Price threshold check button and currency input
  add(FrameFactory:CreateCheckButton(nil, "Small", L.PRICE_THRESHOLD_TEXT, nil,
    L.PRICE_THRESHOLD_TOOLTIP, DejunkDB.DestroyUsePriceThreshold, cbCallback))
  add(FrameFactory:CreateCurrencyInputFrame(nil, "GameFontNormalSmall", DejunkDB.DestroyPriceThreshold))

  -- Destroy heading
  local destroyHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  destroyHeading:SetText(L.DESTROY_TEXT..":")
  add(destroyHeading)

  -- Destroy poor
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.POOR_TEXT, Colors.Poor, L.DESTROY_ALL_TOOLTIP, DejunkDB.DestroyPoor, cbCallback))

  -- Destroy Inclusions
  local inclusionsText = Tools:GetColorString(L.INCLUSIONS_TEXT, Colors.Inclusions)
  add(FrameFactory:CreateCheckButton(nil, "Small", inclusionsText, nil,
    format(L.DESTROY_LIST_TOOLTIP, inclusionsText), DejunkDB.DestroyInclusions, cbCallback))

  -- Ignore heading
  local ignoreHeading = FrameFactory:CreateFontString(ui.SettingsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  ignoreHeading:SetText(L.IGNORE_TEXT..":")
  add(ignoreHeading)

  -- Ignore Exclusions
  local exclusionsText = Tools:GetColorString(L.EXCLUSIONS_TEXT, Colors.Exclusions)
  add(FrameFactory:CreateCheckButton(nil, "Small", exclusionsText, nil,
    format(L.DESTROY_IGNORE_LIST_TOOLTIP, exclusionsText), DejunkDB.DestroyIgnoreExclusions, cbCallback))
end
