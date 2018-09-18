-- ListButton: a customized DFL faux scroll frame for visually displaying list data.

local AddonName, Addon = ...

-- Lib
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL
local DTL = Addon.Libs.DTL

-- Upvalues
local GetMouseFocus = GetMouseFocus
local IsControlKeyDown = IsControlKeyDown
local IsDressableItem, DressUpVisual = IsDressableItem, DressUpVisual

-- Modules
local ListButton = Addon.Objects.ListButton
local Colors = Addon.Colors

-- Variables
local ICON_TEX_COORD = {0.08, 0.92, 0.08, 0.92}

-- ============================================================================
-- Creation Function
-- ============================================================================

-- Creates and returns a Dejunk list frame button.
-- @param parent - the parent frame
function ListButton:Create(parent)
  local button = Addon.Objects.FauxButton:Create(parent)

  button.Icon = DFL.Creator:CreateTexture(button, "ARTWORK")
  button.Icon:ClearAllPoints()
  button.Icon:SetPoint(DFL.Points.LEFT, DFL:Padding(0.5), 0)

  button.Text:SetPoint(DFL.Points.LEFT, button.Icon, DFL.Points.RIGHT, DFL:Padding(0.5), 0)
  button.Text:SetPoint(DFL.Points.RIGHT, -DFL:Padding(0.5), 0)

  -- Mixins
  DFL:AddMixins(button, self.Functions)
  
  return button
end

-- ============================================================================
-- Functions
-- ============================================================================

local Functions = ListButton.Functions

function Functions:OnClick(button, down)
  if (button == "LeftButton") then
    if IsControlKeyDown() then
      if IsDressableItem(self.Data.ItemID) then
        DressUpVisual(self.Data.ItemLink)
      end
    else
      self:GetParent():AddCursorItem()
    end
  elseif (button == "RightButton") then
    self:GetParent():RemoveItem(self.Data.ItemID)
  end
end

function Functions:OnEnter()
  DTL:ShowHyperlink(self, DFL.Anchors.TOP, self.Data.ItemLink)
end

function Functions:OnRefresh()
  local size = self:GetHeight() - DFL:Padding()
  self.Icon:SetSize(size, size)
  self.Icon:SetTexture(self.Data.Texture)
  self.Icon:SetTexCoord(unpack(ICON_TEX_COORD))
  self.Text:SetText(format("[%s]", self.Data.Name))
  self.Text:SetTextColor(unpack(DCL:GetColorByQuality(self.Data.Quality)))
end
