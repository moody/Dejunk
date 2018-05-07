-- TitleFrame: displays a menu title, character specific settings button, and close button.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L

local DFL = Addon.Libs.DFL
local Factory = DFL.Factory
local Tools = DFL.Tools

-- Dejunk
local TitleFrame = Addon.Frames.TitleFrame

-- local Colors = Addon.Colors
local ParentFrame = Addon.Frames.ParentFrame

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function TitleFrame:OnInitialize()
  local frame = self.Frame
  frame:SetEqualized(true)
  frame:SetFlexible(true)
  frame:SetSpacing(Tools:Padding())
  
  self:CreateLeft()
  self:CreateMiddle()
  self:CreateRight()

  self.CreateLeft = nil
  self.CreateMiddle = nil
  self.CreateRight = nil
end

function TitleFrame:CreateLeft()
  local frame = self.Frame

  -- Main container
  local container = Factory.Container:Create(frame, Factory.Alignments.TOPLEFT, Factory.Directions.COLUMN)
  container:SetSpacing(Tools:Padding(0.25))
  
  -- Character Specific Settings check button
  local charSpec = Factory.CheckButton:Create(frame, "GameFontNormalSmall",
    L.CHARACTER_SPECIFIC_TEXT, L.CHARACTER_SPECIFIC_TOOLTIP)
  charSpec:SetCheckRefreshFunction(function() return not DejunkPerChar.UseGlobal end)
  -- charSpec:SetColors(Colors.LabelText, Colors.ParentFrame)
  function charSpec:OnClick() Addon.Core:ToggleCharacterSpecificSettings() end
  -- Tools:AddBorder(charSpec._checkButton, unpack(Colors.ScrollFrame))
  container:Add(charSpec)
  
  do
    local c = Factory.Container:Create(container)
    c:SetSpacing(Tools:Padding(0.25))

    -- Item tooltip check button
    local itemTooltip = Factory.CheckButton:Create(frame, "GameFontNormalSmall",
      L.ITEM_TOOLTIP_TEXT, L.ITEM_TOOLTIP_TOOLTIP)
    itemTooltip:SetCheckRefreshFunction(function() return DejunkGlobal.ItemTooltip end)
    function itemTooltip:OnClick()
      DejunkGlobal.ItemTooltip = not DejunkGlobal.ItemTooltip
    end
    c:Add(itemTooltip)

    -- Minimap Icon check button
    local minimapIcon = Factory.CheckButton:Create(frame, "GameFontNormalSmall",
      L.MINIMAP_CHECKBUTTON_TEXT, L.MINIMAP_CHECKBUTTON_TOOLTIP)
    minimapIcon:SetCheckRefreshFunction(function() return not DejunkGlobal.Minimap.hide end)
    -- minimapIcon:SetColors(Colors.LabelText, Colors.ParentFrame)
    function minimapIcon:OnClick() Addon.MinimapIcon:Toggle() end
    -- Tools:AddBorder(minimapIcon._checkButton, unpack(Colors.ScrollFrame))
    c:Add(minimapIcon)

    container:Add(c)
  end
  
  frame:Add(container)
end

function TitleFrame:CreateMiddle()
  local frame = self.Frame

  -- Main container
  local container = Factory.Container:Create(frame, Factory.Alignments.CENTER)

  -- Title
  local title = Factory.FontString:Create(frame, "OVERLAY",
    "NumberFontNormalHuge", strupper(AddonName))
  title:SetShadowOffset(2, -1.5)
  -- title:SetColors(Colors.Title, Colors.TitleShadow)
  self.TitleFontString = title
  container:Add(title)

  frame:Add(container)
end

function TitleFrame:CreateRight()
  local frame = self.Frame
  
  -- Main container
  local container = Factory.Container:Create(frame, Factory.Alignments.TOPRIGHT)
  container:SetSpacing(Tools:Padding(0.25))

  -- Dejunk/Destroy button
  local dejunkDestroy = Factory.Button:Create(frame, "GameFontNormal", L.DESTROY_TEXT)
  function dejunkDestroy:OnClick() Addon.Core:SwapDejunkDestroyChildFrames() end
  self.DejunkDestroyButton = dejunkDestroy
  container:Add(dejunkDestroy)
  
  -- Close Button
  local close = Factory.Button:Create(frame, "GameFontNormal", "X")
  close.SetEnabled = nop
  -- close:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  function close:OnClick() ParentFrame:Hide() end
  container:Add(close)
  self._closeButton = close

  frame:Add(container)
end

-- ============================================================================
-- General Functions
-- ============================================================================

-- Updates the title text and dejunk/destroy button.
function TitleFrame:SetTitleToDejunk()
  self.TitleFontString:SetText(strupper(AddonName))
  self.DejunkDestroyButton:SetText(L.DESTROY_TEXT)
end

-- Updates the title text and dejunk/destroy button.
function TitleFrame:SetTitleToDestroy()
  self.TitleFontString:SetText(strupper(L.DESTROY_TEXT))
  self.DejunkDestroyButton:SetText(AddonName)
end
