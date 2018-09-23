-- TitleFrame: displays a menu title, character specific settings button, and close button.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Modules
local TitleFrame = Addon.Frames.TitleFrame

local Colors = Addon.Colors
local DB = Addon.DB
local ParentFrame = Addon.Frames.ParentFrame
local DejunkChildFrame = Addon.Frames.DejunkChildFrame
local ProfileChildFrame = Addon.Frames.ProfileChildFrame

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
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOPLEFT, DFL.Directions.DOWN, DFL.Layouts.FILL_W)
  frame:SetSpacing(DFL:Padding(0.25))

  -- Profiles button
  local profiles = DFL.Button:Create(parent, L.PROFILES_TEXT)
  profiles:SetColors(Colors.None, Colors.Border, Colors.LabelText, Colors.ButtonTextHi, Colors.Border)
  function profiles:OnClick()
    if (self:GetText() == L.PROFILES_TEXT) then
      ParentFrame:SetContent(ProfileChildFrame)
      self:SetText(L.MAIN_MENU_TEXT)
    else
      ParentFrame:SetContent(DejunkChildFrame)
      self:SetText(L.PROFILES_TEXT)
    end
  end
  frame:Add(profiles)
  
  parent:Add(frame)
end

function TitleFrame:CreateMiddle()
  local parent = self.Frame

  -- Main frame
  local frame = DFL.Frame:Create(parent, DFL.Alignments.TOP)

  -- Title
  local title = DFL.FontString:Create(parent, strupper(AddonName), DFL.Fonts.NumberHuge)
  -- title:SetShadowOffset(2, -1.5)
  title:SetColors(Colors.Title, Colors.TitleShadow)
  self.TitleFontString = title
  frame:Add(title)

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

  -- Scheme button
  local scheme = DFL.Button:Create(parent, L.COLOR_SCHEME_TEXT)
  scheme:SetColors(Colors.None, Colors.Border, Colors.LabelText, Colors.ButtonTextHi, Colors.Border)
  function scheme:OnClick() Colors:NextScheme() end
  frame:Add(scheme)
  
  -- Close Button
  local close = DFL.Button:Create(parent, "X")
  close:SetMinWidth(30)
  close:SetColors(Colors.None, Colors.Border, Colors.LabelText, Colors.ButtonTextHi, Colors.Border)
  function close:OnClick() ParentFrame:Hide() end
  close.SetEnabled = nop
  frame:Add(close)

  parent:Add(frame)
end
