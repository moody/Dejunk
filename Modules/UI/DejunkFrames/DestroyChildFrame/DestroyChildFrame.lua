-- DestroyChildFrame: displays options for automatically destroying items.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DestroyChildFrame = DJ.DejunkFrames.DestroyChildFrame

local DestroyChildOptionsFrame = DJ.DejunkFrames.DestroyChildOptionsFrame
local DestroyChildListFrame = DJ.DejunkFrames.DestroyChildListFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory
local ListManager = DJ.ListManager

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function DestroyChildFrame:OnInitialize()
  local ui = self.UI
  local frame = self.Frame

  -- Start Destroying button
  ui.StartDestroyingButton = FrameFactory:CreateButton(frame, "GameFontNormal", "Start Destroying (L)")
  ui.StartDestroyingButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", Tools:Padding(), 0)
  ui.StartDestroyingButton:SetScript("OnClick", function(self, button, down)
    print("StartDestroyingButton clicked")
  end)

  -- DestroyChildFrame
  DestroyChildOptionsFrame:Initialize()
  DestroyChildOptionsFrame:SetParent(frame)
  DestroyChildOptionsFrame:SetPoint({"TOPLEFT", frame})
  --DestroyChildOptionsFrame:SetPoint({"BOTTOMLEFT", frame})
  --DestroyChildOptionsFrame:SetPoint({"BOTTOMLEFT", ui.StartDestroyingButton, "TOPLEFT", 0, -Tools:Padding(0.5)})

  -- DestroyChildListFrame
  DestroyChildListFrame:Initialize()
  DestroyChildListFrame:SetParent(frame)
  DestroyChildListFrame:SetPoint({"BOTTOMRIGHT", frame})
  --DestroyChildListFrame:SetPoint({"BOTTOMLEFT", DestroyChildOptionsFrame.Frame, "BOTTOMRIGHT", Tools:Padding(0.5), 0})
  DestroyChildListFrame:SetPoint({"BOTTOMLEFT", ui.StartDestroyingButton, "BOTTOMRIGHT", 0, 0})
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = DestroyChildFrame.Show

  function DestroyChildFrame:Show()
    DestroyChildOptionsFrame:Show()
    DestroyChildListFrame:Show()
    show(self)
  end
end

do -- Hook Hide
  local hide = DestroyChildFrame.Hide

  function DestroyChildFrame:Hide()
    DestroyChildOptionsFrame:Hide()
    DestroyChildListFrame:Hide()
    hide(self)
  end
end

do -- Hook Enable
  local enable = DestroyChildFrame.Enable

  function DestroyChildFrame:Enable()
    DestroyChildOptionsFrame:Enable()
    DestroyChildListFrame:Enable()
    enable(self)
  end
end

do -- Hook Disable
  local disable = DestroyChildFrame.Disable

  function DestroyChildFrame:Disable()
    DestroyChildOptionsFrame:Disable()
    DestroyChildListFrame:Disable()
    disable(self)
  end
end

do -- Hook Refresh
  local refresh = DestroyChildFrame.Refresh

  function DestroyChildFrame:Refresh()
    DestroyChildOptionsFrame:Refresh()
    DestroyChildListFrame:Refresh()
    refresh(self)
  end
end

-- @Override
function DestroyChildFrame:Resize()
  local ui = self.UI

  ui.StartDestroyingButton:Resize()
  DestroyChildOptionsFrame:Resize()
  DestroyChildListFrame:Resize()

  -- Keep options and destroy button at equal width
  local leftWidth = max(ui.StartDestroyingButton:GetWidth(), DestroyChildOptionsFrame:GetWidth())
  ui.StartDestroyingButton:SetWidth(leftWidth)
  DestroyChildOptionsFrame:SetWidth(leftWidth)

  local newWidth = leftWidth + Tools:Padding(0.5) + DestroyChildListFrame:GetWidth()

  local leftHeight = DestroyChildOptionsFrame:GetHeight() + Tools:Padding(0.5) + ui.StartDestroyingButton:GetHeight()
  local newHeight = max(leftHeight, DestroyChildListFrame:GetHeight())

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

-- --[[
-- //*******************************************************************
-- //                         Get & Set Functions
-- //*******************************************************************
-- --]]
--
-- do -- Hook SetWidth
--   local setWidth = DestroyChildFrame.SetWidth
--
--   function DestroyChildFrame:SetWidth(width)
--     -- DestroyChildOptionsFrame:SetWidth(width)
--     -- DestroyChildListFrame:SetWidth(width)
--     setWidth(self, width)
--   end
-- end
