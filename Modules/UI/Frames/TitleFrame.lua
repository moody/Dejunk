-- TitleFrame: displays a menu title, character specific settings button, and close button.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Dejunk
local TitleFrame = Addon.Frames.TitleFrame

local Colors = Addon.Colors
local ParentFrame = Addon.Frames.ParentFrame

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function TitleFrame:OnInitialize()
  local frame = self.Frame
  frame:SetLayout(DFL.Layouts.FLEX_EQUAL)
  frame:SetSpacing(DFL:Padding())
  
  self:CreateLeft()
  self:CreateMiddle()
  self:CreateRight()

  self.CreateLeft = nil
  self.CreateMiddle = nil
  self.CreateRight = nil
end

function TitleFrame:CreateLeft()
  local parent = self.Frame

  -- Main frame
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOPLEFT, DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.25))
  
  -- Character Specific Settings check button
  local charSpec = DFL.CheckButton:Create(parent, L.CHARACTER_SPECIFIC_TEXT, L.CHARACTER_SPECIFIC_TOOLTIP, DFL.Fonts.Small)
  charSpec:SetCheckRefreshFunction(function() return not DejunkPerChar.UseGlobal end)
  charSpec:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.ScrollFrame)
  function charSpec:OnClick() Addon.Core:ToggleCharacterSpecificSettings() end
  frame:Add(charSpec)
  
  do -- Item tooltip & minimap icon check buttons
    local f = DFL.Frame:Create(frame)
    f:SetSpacing(DFL:Padding(0.25))

    -- Item tooltip check button
    local itemTooltip = DFL.CheckButton:Create(parent, L.ITEM_TOOLTIP_TEXT, L.ITEM_TOOLTIP_TOOLTIP, DFL.Fonts.Small)
    itemTooltip:SetCheckRefreshFunction(function() return DejunkGlobal.ItemTooltip end)
    itemTooltip:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.ScrollFrame)
    function itemTooltip:OnClick()
      DejunkGlobal.ItemTooltip = not DejunkGlobal.ItemTooltip
    end
    f:Add(itemTooltip)

    -- Minimap Icon check button
    local minimapIcon = DFL.CheckButton:Create(parent, L.MINIMAP_CHECKBUTTON_TEXT, L.MINIMAP_CHECKBUTTON_TOOLTIP, DFL.Fonts.Small)
    minimapIcon:SetCheckRefreshFunction(function() return not DejunkGlobal.Minimap.hide end)
    minimapIcon:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.ScrollFrame)
    function minimapIcon:OnClick() Addon.MinimapIcon:Toggle() end
    f:Add(minimapIcon)

    frame:Add(f)
  end
  
  parent:Add(frame)
end

function TitleFrame:CreateMiddle()
  local parent = self.Frame

  -- Main frame
  local frame = DFL.Frame:Create(parent, DFL.Alignments.CENTER)

  -- Title
  local title = DFL.FontString:Create(parent, strupper(AddonName), DFL.Fonts.NumberHuge)
  title:SetShadowOffset(2, -1.5)
  title:SetColors(Colors.Title, Colors.TitleShadow)
  self.TitleFontString = title
  frame:Add(title)

  parent:Add(frame)
end

function TitleFrame:CreateRight()
  local parent = self.Frame
  
  -- Main frame
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOPRIGHT)
  frame:SetSpacing(DFL:Padding(0.25))

  -- Scheme button
  local schemeButton = DFL.Button:Create(parent, L.COLOR_SCHEME_TEXT)
  schemeButton:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  function schemeButton:OnClick() Colors:NextScheme() end
  frame:Add(schemeButton)
  
  -- Close Button
  local close = DFL.Button:Create(parent, "X")
  close.SetEnabled = nop
  close:SetColors(Colors.Button, Colors.ButtonHi, Colors.ButtonText, Colors.ButtonTextHi)
  function close:OnClick() ParentFrame:Hide() end
  frame:Add(close)

  parent:Add(frame)
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
