-- TitleFrame: displays a menu title, character specific settings button, and close button.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Modules
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
  charSpec:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.Border)
  function charSpec:GetUserValue() return not DejunkPerChar.UseGlobal end
  function charSpec:SetUserValue() Addon.Core:ToggleCharacterSpecificSettings() end
  frame:Add(charSpec)
  
  do -- Item tooltip & minimap icon check buttons
    local f = DFL.Frame:Create(frame)
    f:SetSpacing(DFL:Padding(0.25))

    -- Item tooltip check button
    local itemTooltip = DFL.CheckButton:Create(parent, L.ITEM_TOOLTIP_TEXT, L.ITEM_TOOLTIP_TOOLTIP, DFL.Fonts.Small)
    itemTooltip:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.Border)
    function itemTooltip:GetUserValue() return DejunkGlobal.ItemTooltip end
    function itemTooltip:SetUserValue() DejunkGlobal.ItemTooltip = not DejunkGlobal.ItemTooltip end
    f:Add(itemTooltip)

    -- Minimap Icon check button
    local minimapIcon = DFL.CheckButton:Create(parent, L.MINIMAP_CHECKBUTTON_TEXT, L.MINIMAP_CHECKBUTTON_TOOLTIP, DFL.Fonts.Small)
    minimapIcon:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.Border)
    function minimapIcon:GetUserValue() return not DejunkGlobal.Minimap.hide end
    function minimapIcon:SetUserValue() Addon.MinimapIcon:Toggle() end
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

  -- Mouse over and click functionality
  frame:SetScript("OnEnter", function()
    title:SetColors(Colors.LabelText, Colors.TitleShadow)
    title:Refresh()
  end)
  frame:SetScript("OnLeave", function()
    title:SetColors(Colors.Title, Colors.TitleShadow)
    title:Refresh()
  end)
  frame:SetScript("OnMouseDown", function() Colors:NextScheme() end)

  parent:Add(frame)
end

function TitleFrame:CreateRight()
  local parent = self.Frame
  
  -- Main frame
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOPRIGHT)
  frame:SetLayout(DFL.Layouts.FLOW_EQUAL_H)
  frame:SetSpacing(DFL:Padding(0.25))

  -- Start destroying button
  local destroy = DFL.Button:Create(parent, L.START_DESTROYING_BUTTON_TEXT)
  destroy:SetColors(Colors.None, Colors.Border, Colors.LabelText, Colors.ButtonTextHi, Colors.Border)
  function destroy:OnClick() Addon.Destroyer:StartDestroying() end
  frame:Add(destroy)
  
  -- Close Button
  local close = DFL.Button:Create(parent, "X")
  close:SetMinWidth(30)
  close:SetColors(Colors.None, Colors.Border, Colors.LabelText, Colors.ButtonTextHi, Colors.Border)
  function close:OnClick() ParentFrame:Hide() end
  close.SetEnabled = nop
  frame:Add(close)

  parent:Add(frame)
end
