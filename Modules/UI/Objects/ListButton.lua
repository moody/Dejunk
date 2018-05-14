-- ListButton: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DFL = Addon.Libs.DFL

-- Upvalues
local GetMouseFocus = GetMouseFocus
local IsAltKeyDown, IsShiftKeyDown = IsAltKeyDown, IsShiftKeyDown

-- Addon
local ListButton = Addon.Objects.ListButton
ListButton.Scripts = {}

local ListManager = Addon.ListManager

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function ListButton:Create(parent) 
    local button = DFL.Creator:CreateButton(parent)
    -- DFL:AddBorder(button)

    button.Texture = DFL.Creator:CreateTexture(button)
    button.Texture:SetColorTexture(unpack(DFL.Colors.Button))

    button.Icon = DFL.Creator:CreateTexture(button, "ARTWORK")
    button.Icon:ClearAllPoints()
    button.Icon:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)
    button.Icon:SetWidth(Addon.Consts.LIST_BUTTON_ICON_SIZE)
    button.Icon:SetHeight(Addon.Consts.LIST_BUTTON_ICON_SIZE)

    button.Text = DFL.Creator:CreateFontString(button)
    button.Text:SetPoint(DFL.Points.LEFT, button.Icon, DFL.Points.RIGHT, DFL:Padding(0.5), 0)
    button.Text:SetPoint(DFL.Points.RIGHT, -DFL:Padding(0.5), 0)
    button.Text:SetWordWrap(false)
    button.Text:SetJustifyH("LEFT")

    -- Mixins
    DFL:AddDefaults(button)
    DFL:AddMixins(button, self.Functions)
    DFL:AddScripts(button, self.Scripts)

    button:SetMinWidth(300)
    button:SetMinHeight(32)
    button:SetColors()
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

  function Functions:SetColors(color, colorHi)
    self._color = color or self._color or DFL.Colors.Button
    self._colorHi = colorHi or self._colorHi or DFL.Colors.ButtonHi
  end

  function Functions:Refresh()
    if not self.Item then self:Hide() return end

    -- Texture
    if self:IsEnabled() and (GetMouseFocus() == self) then
      self:GetScript("OnEnter")(self)
    else
      -- OnLeave also hides the current tooltip, so we can't call it
      self.Texture:SetColorTexture(unpack(self._color))
    end

    -- Data
    self.Icon:SetTexture(self.Item.Texture)
    self.Text:SetText(format("[%s]", self.Item.Name))
    self.Text:SetTextColor(unpack(Addon.Colors:GetColorByQuality(self.Item.Quality)))
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = ListButton.Scripts

  function Scripts:OnEnter()
    self.Texture:SetColorTexture(unpack(self._colorHi))
    Addon.Tools:ShowItemTooltip(self, DFL.Anchors.TOP, self.Item.ItemLink)
  end

  function Scripts:OnLeave()
    self.Texture:SetColorTexture(unpack(self._color))
    DFL:HideTooltip()
  end
end
