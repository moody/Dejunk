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

-- Dejunk_ParentFrame: displays the TitleFrame and a child frame such as BasicChildFrame.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local ParentFrame = DJ.DejunkFrames.ParentFrame

local Colors = DJ.Colors
local Consts = DJ.Consts
local Tools = DJ.Tools
local FrameFactory = DJ.FrameFactory
local FrameFader = DJ.FrameFader
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

-- @Override
function ParentFrame:OnDeinitialize()
  TitleFrame:Deinitialize()

  if currentChild then
    currentChild:Deinitialize()
    currentChild = nil
  end
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
-- @param fadeTime - the time in seconds to fade in and fade out child frames
function ParentFrame:SetCurrentChild(newChild, callback, fadeTime)
  assert(newChild ~= nil, "newChild cannot be nil")

  local point = {"TOPLEFT", TitleFrame.Frame, "BOTTOMLEFT", 0, -Tools:Padding()}

  if currentChild then currentChild:Disable() end

  local switchChild = function()
    currentChild = newChild
    currentChild:Initialize()
    currentChild:SetParent(self.Frame)
    currentChild:SetPoint(point)

    if callback then callback() end
  end

  if self.Frame:IsVisible() then
    fadeTime = (fadeTime or 0.5)

    local fadeIn = function(time)
      switchChild()

      -- NOTE: two calls to resize is pretty dumb, but it seems to be the only way to make sure
      -- that everything get resized correctly. Especially if Tools:Measure() is used
      -- in a Dejunk frame's resize function before its UI objects have had a chance
      -- to be displayed for the first time. IT'S CONFUSING AND I DON'T KNOW WHY BUT IT WORKS, OKAY??
      self:Resize()
      self:Resize()

      currentChild.Frame:SetAlpha(0)
      currentChild:Disable()
      FrameFader:FadeIn(currentChild.Frame, time, function()
        currentChild:Enable() end)
    end

    -- if currentChild is nil, just fade in the new one
    if not currentChild then fadeIn(fadeTime) return end

    fadeTime = (fadeTime / 2) -- split time between fade in and fade out

    -- otherwise, fade out currentChild first
    FrameFader:FadeOut(currentChild.Frame, fadeTime, function()
      currentChild:Deinitialize()
      fadeIn(fadeTime)
    end)
  else -- frame is not shown, just get the child ready
    if currentChild then currentChild:Deinitialize() end
    switchChild()
    -- NOTE: see the above note. Resize really shouldn't have to be called here, but it does for reasons.
    -- The second resize happens when Show is called, so that's why only one call to Resize is here.
    self:Resize()
  end
end
