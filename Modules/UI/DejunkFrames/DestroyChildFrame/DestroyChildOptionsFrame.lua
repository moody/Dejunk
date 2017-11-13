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
  ui.StartDestroyingButton:SetScript("OnClick", function(self, button, down)
    print("StartDestroyingButton clicked")
  end)

  ui.SettingsFrame = FrameFactory:CreateScrollingOptionsFrame(frame, "Settings (L)", "GameFontNormalHuge")
  ui.SettingsFrame:SetPoint("TOPLEFT", frame, Tools:Padding(), 0)

  local add = function(option)
    self.UI.SettingsFrame:AddOption(option)
  end

  -- Destroy Poor Items
  local destroyPoorText = format("Destroy %s Items (L)", Tools:GetColorString(L.POOR_TEXT, Colors.Poor))
  for i = 1, 20 do -- DEBUG ONLY
    add(FrameFactory:CreateCheckButton(nil, "Small", destroyPoorText, nil, L.AUTO_SELL_TOOLTIP, nil))
  end

  -- Auto destroy
  local text = "Auto Destroy (L)"
  local tip = "Automatically begin destroying items when your bags become full. (L)"
  add(FrameFactory:CreateCheckButton(nil, "Small", text, nil, tip, nil))
end
