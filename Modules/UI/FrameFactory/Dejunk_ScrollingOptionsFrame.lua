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

-- Dejunk_ScrollingOptionsFrame: contains FrameFactory functions to create and release a scrollable frame containing Dejunk options.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local FrameFactory = DJ.FrameFactory

local Colors = DJ.Colors
local Tools = DJ.Tools
local FramePooler = DJ.FramePooler

--[[
//*******************************************************************
//                  Scrolling Options Frame Functions
//*******************************************************************
--]]

function FrameFactory:CreateScrollingOptionsFrame(parent, title, font)
  local soFrame = FramePooler:CreateFrame(parent)
  soFrame.FF_ObjectType = "ScrollingOptionsFrame"
  soFrame.UI = {}

  local titleButton = self:CreateButton(soFrame, font or "GameFontNormalHuge",
    title, Colors.None, Colors.None, Colors.LabelText, Colors.LabelText)
  soFrame.TitleButton = titleButton

  local scrollFrame = self:CreateScrollFrame(soFrame)
  local slider = scrollFrame.Slider
  soFrame.ScrollFrame = scrollFrame

  -- Initialize points
  titleButton:SetPoint("TOP", soFrame)

  slider:SetPoint("BOTTOMRIGHT", soFrame)
  scrollFrame:SetPoint("BOTTOMLEFT", soFrame)
  scrollFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)

  -- Title button
  titleButton:SetText(titleText)

  -- Displays the slider.
  function soFrame:ShowSlider()
    slider:Show()
    scrollFrame:SetPoint("BOTTOMRIGHT", slider, "BOTTOMLEFT", -Tools:Padding(0.5), 0)
  end

  -- Hides the slider.
  function soFrame:HideSlider()
    slider:Hide()
    scrollFrame:SetPoint("BOTTOMRIGHT", soFrame)
  end

  -- Updates the slider to show or hide depending
  function soFrame:UpdateSliderState()
    if scrollFrame:IsSliderRequired() then
      self:ShowSlider()
    else
      self:HideSlider()
    end
  end

  -- Adds an option object to the underlying scroll frame.
  function soFrame:AddOption(option)
    scrollFrame:AddObject(option)
  end

  -- Gets the minimum width of the frame.
  function soFrame:GetMinWidth()
    local sfWidth = (scrollFrame:GetMinWidth() +
      (slider:GetWidth() + Tools:Padding(0.5)))

    return max(titleButton:GetWidth(), sfWidth)
  end

  -- Gets the minimum height of the frame.
  function soFrame:GetMinHeight()
    return (titleButton:GetHeight() + scrollFrame:GetHeight())
  end

  -- Resizes the frame.
  function soFrame:Resize()
    scrollFrame:Resize()
    self:UpdateSliderState()

    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end

  function soFrame:Refresh()
    titleButton:Refresh()
    scrollFrame:Refresh()
  end

  -- Scripts
  soFrame:SetScript("OnMouseWheel", function(self, delta)
    -- Scroll by 20% on each wheel
    local percent = (select(2, slider:GetMinMaxValues()) * 0.2 * delta)
    slider:SetValue(slider:GetValue() - percent)
  end)

  soFrame:Refresh()

  return soFrame
end

function FrameFactory:EnableScrollingOptionsFrame(soFrame)
  self:EnableScrollFrame(soFrame.ScrollFrame)
end

function FrameFactory:DisableScrollingOptionsFrame(soFrame)
  self:DisableScrollFrame(soFrame.ScrollFrame)
end

function FrameFactory:ReleaseScrollingOptionsFrame(soFrame)
  -- Objects
  self:ReleaseButton(soFrame.TitleButton)
  soFrame.TitleButton = nil

  self:ReleaseScrollFrame(soFrame.ScrollFrame)
  soFrame.ScrollFrame = nil

  -- Variables
  soFrame.FF_ObjectType = nil

  -- Functions
  soFrame.ShowSlider = nil
  soFrame.HideSlider = nil
  soFrame.UpdateSliderState = nil
  soFrame.AddOption = nil
  soFrame.Resize = nil
  soFrame.Refresh = nil

  FramePooler:ReleaseFrame(soFrame)
end
