-- CurrencyField: a customized DFL frame which provides a icon text fields for gold, silver, and copper.

local AddonName, Addon = ...

-- Lib
local DFL = Addon.Libs.DFL

-- Addon
local CurrencyField = Addon.Objects.CurrencyField
CurrencyField.Scripts = {}

local Colors = Addon.Colors
local DejunkDB = Addon.DejunkDB

-- Consts
local MONEY_ICONS_TEXTURE = "Interface\\MoneyFrame\\UI-MoneyIcons"
local TEXTURE_SIZE = 12
local GOLD_TEX_COORD = {0, 0.25, 0, 1}
local SILVER_TEX_COORD = {0.25, 0.5, 0, 1}
local COPPER_TEX_COORD = {0.5, 0.75, 0, 1}

local MAX_GOLD_DIGIT = 2
local MAX_SILVER_DIGIT = 2
local MAX_COPPER_DIGIT = 2

-- ============================================================================
-- Creation Function
-- ============================================================================

function CurrencyField:Create(parent, svKey, font)
  assert((type(svKey) == "string") and (type(DejunkDB:Get(svKey)) == "table"))

  local frame = DFL.Frame:Create(parent,
    DFL.Alignments.LEFT, DFL.Directions.RIGHT)
  frame:SetSpacing(DFL:Padding(0.5))

  -- Gold
  local goldEditBox = DFL.EditBox:Create(frame, MAX_GOLD_DIGIT, true, font)
  goldEditBox._editBox:SetJustifyH("CENTER")
  goldEditBox._editBox._svKey = svKey..".Gold"
  goldEditBox:SetMinWidth(35)
  frame:Add(goldEditBox)

  local goldTexture = DFL.Creator:CreateTexture(frame)
  goldTexture:ClearAllPoints()
  goldTexture:SetTexture(MONEY_ICONS_TEXTURE)
  goldTexture:SetTexCoord(unpack(GOLD_TEX_COORD))
  goldTexture:SetSize(TEXTURE_SIZE, TEXTURE_SIZE)
  frame:Add(goldTexture)
    
  -- Silver
  local silverEditBox = DFL.EditBox:Create(frame, MAX_SILVER_DIGIT, true, font)
  silverEditBox._editBox:SetJustifyH("CENTER")
  silverEditBox._editBox._svKey = svKey..".Silver"
  silverEditBox:SetMinWidth(35)
  frame:Add(silverEditBox)

  local silverTexture = DFL.Creator:CreateTexture(frame)
  silverTexture:ClearAllPoints()
  silverTexture:SetTexture(MONEY_ICONS_TEXTURE)
  silverTexture:SetTexCoord(unpack(SILVER_TEX_COORD))
  silverTexture:SetSize(TEXTURE_SIZE, TEXTURE_SIZE)
  frame:Add(silverTexture)

  -- Copper
  local copperEditBox = DFL.EditBox:Create(frame, MAX_COPPER_DIGIT, true, font)
  copperEditBox._editBox:SetJustifyH("CENTER")
  copperEditBox._editBox._svKey = svKey..".Copper"
  copperEditBox:SetMinWidth(35)
  frame:Add(copperEditBox)
  
  local copperTexture = DFL.Creator:CreateTexture(frame)
  copperTexture:ClearAllPoints()
  copperTexture:SetTexture(MONEY_ICONS_TEXTURE)
  copperTexture:SetTexCoord(unpack(COPPER_TEX_COORD))
  copperTexture:SetSize(TEXTURE_SIZE, TEXTURE_SIZE)
  frame:Add(copperTexture)

  -- References for OnTabPressed
  -- ... Gold <-> Silver <-> Copper <-> Gold ...
  goldEditBox._editBox._prevEditBox = copperEditBox._editBox
  goldEditBox._editBox._nextEditBox = silverEditBox._editBox
  
  silverEditBox._editBox._prevEditBox = goldEditBox._editBox
  silverEditBox._editBox._nextEditBox = copperEditBox._editBox

  copperEditBox._editBox._prevEditBox = silverEditBox._editBox
  copperEditBox._editBox._nextEditBox = goldEditBox._editBox

  -- Mixins
  DFL:AddMixins(frame, self.Functions)
  DFL:AddScripts(goldEditBox._editBox, self.Scripts)
  DFL:AddScripts(silverEditBox._editBox, self.Scripts)
  DFL:AddScripts(copperEditBox._editBox, self.Scripts)

  frame:SetColors()
  frame:Refresh()

  return frame
end

-- ============================================================================
-- Functions
-- ============================================================================

do
  local Functions = CurrencyField.Functions

  function Functions:SetColors(textColor, textureColor, borderColor)
    -- Refresh value of edit boxes
    for k, editBox in pairs(self:GetChildren()) do
      if DFL:IsType(editBox, DFL.EditBox:GetType()) then
        editBox:SetColors (
          textColor or Colors.LabelText,
          textureColor or Colors.ParentFrame,
          borderColor or Colors.ScrollFrame
        )
      end
    end
  end

  function Functions:Refresh()
    DFL.Frame.Functions.Refresh(self)

    -- Refresh value of edit boxes
    for k, v in pairs(self:GetChildren()) do
      local editBox = v._editBox
      if editBox then
        editBox:SetText(DejunkDB:Get(editBox._svKey))
      end
    end
  end
end

-- ============================================================================
-- Scripts
-- ============================================================================

do
  local Scripts = CurrencyField.Scripts

  function Scripts:OnEditFocusGained()
    self:HighlightText()
  end

  function Scripts:OnEditFocusLost()
    self:HighlightText(0, 0)
    self:SetText(DejunkDB:Get(self._svKey))
  end

  function Scripts:OnTextChanged()
    local value = self:GetNumber()
    if (value ~= DejunkDB:Get(self._svKey)) then
      DejunkDB:Set(self._svKey, floor(abs(value)))
    end
  end

  function Scripts:OnTabPressed()
    if (IsShiftKeyDown()) then
      self._prevEditBox:SetFocus()
    else
      self._nextEditBox:SetFocus()
    end
  end
end
