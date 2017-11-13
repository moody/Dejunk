-- Dejunk_ParentFrame: displays the TitleFrame and a child frame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local ParentFrame = DJ.DejunkFrames.ParentFrame

local Colors = DJ.Colors
local Consts = DJ.Consts
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory
local TitleFrame = DJ.DejunkFrames.TitleFrame

-- Variables
local currentChild = nil -- currently displayed child frame

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function ParentFrame:OnInitialize()
  local frame = self.Frame

  frame:SetColors(Colors.ParentFrame)
  frame:SetWidth(Consts.MIN_WIDTH)
	frame:SetHeight(Consts.MIN_HEIGHT)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetFrameStrata("HIGH")

  frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	table.insert(UISpecialFrames, frame:GetName()) -- Makes the frame hide when Esc is pressed
	frame:Hide()

  TitleFrame:Initialize()
  TitleFrame:SetPoint({"TOPLEFT", frame})
  TitleFrame:SetParent(frame)
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

do -- Hook Show
  local show = ParentFrame.Show

  function ParentFrame:Show()
    self:Resize()
    show(self)
  end
end

-- @Override
function ParentFrame:Enable()
  TitleFrame:Enable()

  if currentChild then
    currentChild:Enable() end

  self.Frame:SetAlpha(1)
end

-- @Override
function ParentFrame:Disable()
  TitleFrame:Disable()

  if currentChild then
    currentChild:Disable() end

  self.Frame:SetAlpha(0.75)
end

do -- Hook Refresh
  local refresh = ParentFrame.Refresh

  function ParentFrame:Refresh()
    refresh(self)
    TitleFrame:Refresh()
    if currentChild then
      currentChild:Refresh()
    end
  end
end

-- @Override
function ParentFrame:Resize()
  --[[ Resize Algorithm
    1. Resize each child frame
    2. Get longest width of child frames (max() calls between child frames)
    3. Get total height of child frames (sum of all child frame heights)
    4. SetWidth on all child frames to the width calculated in step 2.
    5. Set width and height on parent frame as found in step 2 and 3.
  ]]

  local newWidth = 0
  local newHeight = 0

  local childFrames = { TitleFrame, currentChild }

  for i, childFrame in ipairs(childFrames) do
    childFrame:Resize()
    newWidth = max(newWidth, childFrame:GetWidth())
    newHeight = (newHeight + childFrame:GetHeight() + Tools:Padding())
  end

  --[[ Well, I changed my mind.
  -- 16:10 width if possible. It just looks better than a square, okay?
  local ratioWidth = ((newHeight / 10) * 16)
  newWidth = max(newWidth, ratioWidth)
  --]]

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetWidth
  local setWidth = ParentFrame.SetWidth

  function ParentFrame:SetWidth(width)
    setWidth(self, width)
    TitleFrame:SetWidth(width)
    if currentChild then currentChild:SetWidth(width) end
  end
end

-- Gets the current child being displayed.
-- @return - the current child
function ParentFrame:GetCurrentChild()
  return currentChild
end

-- Sets the frame to be displayed below the TitleFrame.
-- @param newChild - a Dejunk frame to be set as the new child
-- @param callback - a function to be called once the new child has been set
function ParentFrame:SetCurrentChild(newChild, callback)
  assert(newChild ~= nil, "newChild cannot be nil")

  local point = {"TOPLEFT", TitleFrame.Frame, "BOTTOMLEFT", 0, -Tools:Padding()}

  if currentChild then currentChild:Hide() end

  currentChild = newChild

  if not currentChild.Initialized then
    currentChild:Initialize()
    currentChild:Resize() -- NOTE: This is a band-aid to prevent certain UI glitches.
  end

  currentChild:SetParent(self.Frame)
  currentChild:SetPoint(point)
  currentChild:Show()

  if callback then callback() end

  self:Resize()
end
