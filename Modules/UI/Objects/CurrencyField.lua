-- CurrencyField: a customized DFL frame which provides a icon text fields for gold, silver, and copper.

local AddonName, Addon = ...

-- Lib
local DFL = Addon.Libs.DFL

-- Addon
local CurrencyField = Addon.Objects.CurrencyField

local Colors = Addon.Colors
local DB = Addon.DB

-- Consts
local MONEY_ICONS_TEXTURE = "Interface\\MoneyFrame\\UI-MoneyIcons"
local GOLD_TEX_COORD = {0, 0.25, 0, 1}
local SILVER_TEX_COORD = {0.25, 0.5, 0, 1}
local COPPER_TEX_COORD = {0.5, 0.75, 0, 1}

local MAX_GOLD_DIGIT = 3
local MAX_SILVER_DIGIT = 2
local MAX_COPPER_DIGIT = 2

-- ============================================================================
-- Local Functions
-- ============================================================================

local sizer = UIParent:CreateFontString(AddonName.."GetStringWidthSizer", "BACKGROUND")

-- Approximates and returns the minimum width required for a font string.
local function getStringWidth(font, numCharacters, numeric)
  -- Make string of characters
  local char = numeric and "9" or "W"
  local text = ""
  for i=1, numCharacters+2 do text = text..char end
  -- Set font and text
  sizer:SetFontObject(font)
  sizer:SetText(text)
  -- Return width
  return sizer:GetStringWidth()
end

local function getUserValue(self)
  return DB:Get(self._svKey)
end

local function setUserValue(self, value)
  value = floor(abs(value))
  DB:Set(self._svKey, value)
end

local function getEditBox(svKey, maxLetters, font)
  local editBox = DFL.EditBox:Create(frame, maxLetters, true, font)
  editBox:SetMinWidth(getStringWidth(font, maxLetters, true) + DFL:Padding(0.5))
  editBox._editBox:SetScript("OnEditFocusGained", editBox._editBox.HighlightText)
  editBox._editBox:SetJustifyH("CENTER")
  editBox._svKey = svKey
  editBox.GetUserValue = getUserValue
  editBox.SetUserValue = setUserValue
  return editBox
end

local function getTexture(parent, texCoord, size)
  local texture = DFL.Creator:CreateTexture(parent)
  texture:ClearAllPoints()
  texture:SetTexture(MONEY_ICONS_TEXTURE)
  texture:SetTexCoord(unpack(texCoord))
  texture:SetSize(size, size)
  return texture
end

-- ============================================================================
-- Creation Function
-- ============================================================================

function CurrencyField:Create(parent, svKey, font)
  assert((type(svKey) == "string") and (type(DB:Get(svKey)) == "table"))

  local frame = DFL.Frame:Create(parent, DFL.Alignments.LEFT, DFL.Directions.RIGHT)
  frame:SetSpacing(DFL:Padding(0.5))

  -- Create edit boxes
  local goldEditBox = getEditBox(svKey..".Gold", MAX_GOLD_DIGIT, font)
  local silverEditBox = getEditBox(svKey..".Silver", MAX_SILVER_DIGIT, font)
  local copperEditBox = getEditBox(svKey..".Copper", MAX_COPPER_DIGIT, font)

  -- Set up tabbing
  goldEditBox:SetPrevTabTarget(copperEditBox._editBox)
  goldEditBox:SetNextTabTarget(silverEditBox._editBox)
  silverEditBox:SetPrevTabTarget(goldEditBox._editBox)
  silverEditBox:SetNextTabTarget(copperEditBox._editBox)
  copperEditBox:SetPrevTabTarget(silverEditBox._editBox)
  copperEditBox:SetNextTabTarget(goldEditBox._editBox)

  -- Texture size = height of font
  local _, textureSize = goldEditBox._editBox:GetFont()

  -- Add to frame
  frame:Add(goldEditBox)
  frame:Add(getTexture(frame, GOLD_TEX_COORD, textureSize))
  frame:Add(silverEditBox)
  frame:Add(getTexture(frame, SILVER_TEX_COORD, textureSize))
  frame:Add(copperEditBox)
  frame:Add(getTexture(frame, COPPER_TEX_COORD, textureSize))

  -- Mixins
  DFL:AddMixins(frame, self.Functions)

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
        editBox:SetColors(
          textColor or Colors.LabelText,
          textureColor or Colors.ParentFrame,
          borderColor or Colors.ScrollFrame
        )
      end
    end
  end
end
