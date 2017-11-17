-- DejunkChildFrame: combines and displays the DejunkChildOptionsFrame and DejunkChildListsFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DejunkChildFrame = DJ.DejunkFrames.DejunkChildFrame

local Tools = DJ.Tools
local DejunkChildOptionsFrame = DJ.DejunkFrames.DejunkChildOptionsFrame
local DejunkChildListsFrame = DJ.DejunkFrames.DejunkChildListsFrame

-- ============================================================================
--                          Frame Lifecycle Functions
-- ============================================================================

function DejunkChildFrame:OnInitialize()
  DejunkChildOptionsFrame:Initialize()
  DejunkChildOptionsFrame:SetParent(self.Frame)
  DejunkChildOptionsFrame:SetPoint({"TOPLEFT", self.Frame})

  DejunkChildListsFrame:Initialize()
  DejunkChildListsFrame:SetParent(self.Frame)
  DejunkChildListsFrame:SetPoint({"TOPLEFT", DejunkChildOptionsFrame.Frame, "BOTTOMLEFT", 0, -Tools:Padding()})
end

function DejunkChildFrame:OnShow()
  DejunkChildOptionsFrame:Show()
  DejunkChildListsFrame:Show()
end

function DejunkChildFrame:OnHide()
  DejunkChildOptionsFrame:Hide()
  DejunkChildListsFrame:Hide()
end

function DejunkChildFrame:OnEnable()
  DejunkChildOptionsFrame:Enable()
  DejunkChildListsFrame:Enable()
end

function DejunkChildFrame:OnDisable()
  DejunkChildOptionsFrame:Disable()
  DejunkChildListsFrame:Disable()
end

function DejunkChildFrame:OnRefresh()
  DejunkChildOptionsFrame:Refresh()
  DejunkChildListsFrame:Refresh()
end

function DejunkChildFrame:OnResize()
  DejunkChildOptionsFrame:Resize()
  DejunkChildListsFrame:Resize()

  local newWidth = max(DejunkChildOptionsFrame:GetWidth(), DejunkChildListsFrame:GetWidth())
  local _, newHeight = Tools:Measure(self.Frame,
    DejunkChildOptionsFrame.Frame, DejunkChildListsFrame.Frame, "TOPLEFT", "BOTTOMLEFT")

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

function DejunkChildFrame:OnSetWidth(width)
  DejunkChildOptionsFrame:SetWidth(width)
  DejunkChildListsFrame:SetWidth(width)
end
