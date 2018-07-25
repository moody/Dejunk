-- OptionsFrame: a customized DFL scroll frame for displaying options.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Addon
local OptionsFrame = Addon.Objects.OptionsFrame

local Colors = Addon.Colors

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk options frame.
function OptionsFrame:Create(parent, title)
  local frame = DFL.Frame:Create(parent,
    DFL.Alignments.TOP, DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.5))

  local titleFS = DFL.FontString:Create(parent, title)
  local titleColor = Colors.LabelText
  if (title == L.SELL_TEXT) then
    titleColor = Colors.Inclusions
  elseif (title == L.IGNORE_TEXT) then
    titleColor = Colors.Exclusions
  elseif (title == L.DESTROY_TEXT) then
    titleColor = Colors.Destroyables
  end
  titleFS:SetColors(titleColor)
  frame:Add(titleFS)

  -- Scroll frame
  local sf = DFL.ScrollFrame:Create(frame)
  sf:SetColors(Colors.ScrollFrame, Colors.SliderColors)
  sf._scrollChild:SetSpacing(DFL:Padding())
  sf:SetMinHeight(150)
  frame._scrollFrame = sf
  frame:Add(sf)

  -- Mixins
  DFL:AddMixins(frame, self.Functions)
  
  return frame
end

-- ============================================================================
-- Creation Function
-- ============================================================================

do
  local Functions = OptionsFrame.Functions

  function Functions:CreateHeading(text)
    local heading = DFL.Frame:Create(self,
      DFL.Alignments.LEFT, DFL.Directions.DOWN)
    heading:SetSpacing(DFL:Padding(0.5))

    -- Heading label
    local label = DFL.FontString:Create(heading, text)
    label:SetColors(Colors.LabelText)
    heading:Add(label)

    self._scrollFrame:Add(heading)
    return heading
  end

  function Functions:OnSetWidth(width)
    self._scrollFrame:SetWidth(width)
  end
end
