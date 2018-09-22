-- FauxButton: a generic DFL faux scroll frame button for displaying data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local GameTooltip, GetMouseFocus = GameTooltip, GetMouseFocus

-- Modules
local FauxButton = Addon.Objects.FauxButton
FauxButton.Scripts = {}

local Colors = Addon.Colors

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function FauxButton:Create(parent)
  local button = DFL.Creator:CreateButton(parent)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  button.Texture = DFL.Creator:CreateTexture(button)
  button.Texture:SetColorTexture(unpack(Colors.ListButton))

  button.Text = DFL.Creator:CreateFontString(button)
  button.Text:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)
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
  local Functions = FauxButton.Functions

  function Functions:SetData(data)
    if (self.Data == data) then return end
    self.Data = data
    self:Refresh()
  end
  
  function Functions:OnSetEnabled(enabled)
    DFL:SetEnabledAlpha(self, enabled)
  end

  function Functions:Refresh()
    if not self.Data then self:Hide() return end

    -- Texture
    if self:IsEnabled() and (GetMouseFocus() == self) then
      self:GetScript("OnEnter")(self)
    else
      -- OnLeave also hides the current tooltip, so we can't call it
      self.Texture:SetColorTexture(unpack(Colors.ListButton))
    end

    -- Hook
    if self.OnRefresh then self:OnRefresh() end
  end

  function Functions:Resize()
    self:SetWidth(self:GetMinWidth())
    self:SetHeight(self:GetMinHeight())
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = FauxButton.Scripts
  
  function Scripts:OnClick(button, down)
    if self.OnClick then self:OnClick(button, down) end
  end

  function Scripts:OnEnter()
    self.Texture:SetColorTexture(unpack(Colors.ListButtonHi))
    if self.OnEnter then self:OnEnter() end
  end

  function Scripts:OnLeave()
    self.Texture:SetColorTexture(unpack(Colors.ListButton))
    GameTooltip:Hide()
  end
end
