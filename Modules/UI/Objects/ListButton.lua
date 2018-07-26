-- ListButton: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local GetMouseFocus = GetMouseFocus
local IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown =
      IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown
local IsDressableItem, DressUpVisual = IsDressableItem, DressUpVisual

-- Modules
local ListButton = Addon.Objects.ListButton
ListButton.Scripts = {}

local Colors = Addon.Colors

-- Variables
local ICON_TEX_COORD = {0.08, 0.92, 0.08, 0.92}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function ListButton:Create(parent)
  local button = DFL.Creator:CreateButton(parent)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  button.Texture = DFL.Creator:CreateTexture(button)
  button.Texture:SetColorTexture(unpack(Colors.ListButton))

  button.Icon = DFL.Creator:CreateTexture(button, "ARTWORK")
  button.Icon:ClearAllPoints()
  button.Icon:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)
  button.Icon:SetSize(20, 20)

  button.Text = DFL.Creator:CreateFontString(button)
  button.Text:SetPoint(DFL.Points.LEFT, button.Icon, DFL.Points.RIGHT, DFL:Padding(0.5), 0)
  button.Text:SetPoint(DFL.Points.RIGHT, -DFL:Padding(0.5), 0)
  button.Text:SetWordWrap(false)
  button.Text:SetJustifyH("LEFT")

  -- Mixins
  DFL:AddDefaults(button)
  DFL:AddMixins(button, self.Functions)
  DFL:AddScripts(button, self.Scripts)

  button:SetMinWidth(275)
  button:SetMinHeight(32)
  button:Refresh()
  
  return button
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = ListButton.Functions

  function Functions:SetData(data)
    if (self.Item == data) then return end
    self.Item = data
    self:Refresh()
  end
  
  function Functions:OnSetEnabled(enabled)
    DFL:SetEnabledAlpha(self, enabled)
  end

  function Functions:Refresh()
    if not self.Item then self:Hide() return end

    -- Texture
    if self:IsEnabled() and (GetMouseFocus() == self) then
      self:GetScript("OnEnter")(self)
    else
      -- OnLeave also hides the current tooltip, so we can't call it
      self.Texture:SetColorTexture(unpack(Colors.ListButton))
    end

    -- Data
    self.Icon:SetTexture(self.Item.Texture)
    self.Icon:SetTexCoord(unpack(ICON_TEX_COORD))
    self.Text:SetText(format("[%s]", self.Item.Name))
    self.Text:SetTextColor(unpack(DCL:GetColorByQuality(self.Item.Quality)))
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = ListButton.Scripts
  
  function Scripts:OnClick(button, down)
    if (button == "LeftButton") then
      if IsControlKeyDown() then
        if IsDressableItem(self.Item.ItemID) then
          DressUpVisual(self.Item.ItemLink)
        end
      else
        self:GetParent():AddCursorItem()
      end
    elseif (button == "RightButton") then
      self:GetParent():RemoveItem(self.Item.ItemID)
    end
  end

  function Scripts:OnEnter()
    self.Texture:SetColorTexture(unpack(Colors.ListButtonHi))
    Addon.Tools:ShowItemTooltip(self, DFL.Anchors.TOP, self.Item.ItemLink)
  end

  function Scripts:OnLeave()
    self.Texture:SetColorTexture(unpack(Colors.ListButton))
    DFL:HideTooltip()
  end
end
