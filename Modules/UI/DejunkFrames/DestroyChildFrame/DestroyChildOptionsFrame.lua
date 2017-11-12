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

  ui.SettingsFrame:Resize()

  local newWidth = ui.SettingsFrame:GetWidth() + Tools:Padding(2)
  local newHeight = ui.SettingsFrame:GetHeight()

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetWidth
  local setWidth = DestroyChildOptionsFrame.SetWidth

  function DestroyChildOptionsFrame:SetWidth(width)
    local oldWidth = self:GetWidth()
    setWidth(self, width)

    self.UI.SettingsFrame:SetWidth(width)
  end
end

do -- Hook SetHeight
  local setHeight = DestroyChildOptionsFrame.SetHeight

  function DestroyChildOptionsFrame:SetHeight(height)
    local oldHeight = self:GetHeight()
    setHeight(self, height)

    self.UI.SettingsFrame:SetHeight(height)
  end
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

function DestroyChildOptionsFrame:CreateOptions()
  local ui = self.UI

  ui.SettingsFrame = FrameFactory:CreateScrollingOptionsFrame(self.Frame, "Settings (L)", "GameFontNormalHuge")
  ui.SettingsFrame:SetPoint("TOPLEFT", self.Frame, Tools:Padding(), 0)

  local add = function(option)
    self.UI.SettingsFrame:AddOption(option)
  end

  -- Destroy Poor Items
  local destroyPoorText = format("Destroy %s Items (L)", Tools:GetColorString(L.POOR_TEXT, Colors.Poor))
  add(FrameFactory:CreateCheckButton(nil, "Small", destroyPoorText, nil, L.AUTO_SELL_TOOLTIP, nil))

  -- Auto destroy
  local text = "Auto Destroy (L)"
  local tip = "Automatically begin destroying items when your bags become full. (L)"
  add(FrameFactory:CreateCheckButton(nil, "Small", text, nil, tip, nil))
end
