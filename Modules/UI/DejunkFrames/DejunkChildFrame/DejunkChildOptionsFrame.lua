-- DejunkChildOptionsFrame: displays a simple options menu.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local DejunkChildOptionsFrame = DJ.DejunkFrames.DejunkChildOptionsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local FrameFactory = DJ.FrameFactory

-- Variables
DejunkChildOptionsFrame.OptionFrames = {}

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function DejunkChildOptionsFrame:OnInitialize()
  self:CreateOptions()
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

-- @Override
function DejunkChildOptionsFrame:Resize()
  local ui = self.UI
  local frames = self.OptionFrames

  local newWidth = 0
  local newHeight = 0

  -- Get largest width and height of options frames
  for k, v in pairs(frames) do
    v:Resize()
    newWidth = max(newWidth, v:GetWidth())
    newHeight = max(newHeight, v:GetHeight())
  end

  -- Even the sizes of the frames
  for k, v in pairs(frames) do
    v:SetWidth(newWidth)
    v:SetHeight(newHeight)
  end

  -- Resize positioner to keep frames centered
  newWidth = (#frames > 0) and Tools:Measure(self.Frame, frames[1],
    frames[#frames], "LEFT", "RIGHT") or 1
  ui.OptionsPositioner:SetWidth(newWidth)

  -- Add left and right side padding
  newWidth = (newWidth + Tools:Padding(2))

  self:SetWidth(newWidth)
  self:SetHeight(newHeight)
end

--[[
//*******************************************************************
//                         Get & Set Functions
//*******************************************************************
--]]

do -- Hook SetWidth
  local setWidth = DejunkChildOptionsFrame.SetWidth

  function DejunkChildOptionsFrame:SetWidth(width)
    local oldWidth = self:GetWidth()
    setWidth(self, width)

    if (width > oldWidth) then -- resize options frames
      local ui = self.UI
      local frames = self.OptionFrames

      local pad = Tools:Padding(2) + ((#frames - 1) * Tools:Padding());
      local newWidth = ((width - pad) / #frames)

      -- Even the widths of the frames
      for k, v in pairs(frames) do
        v:SetWidth(newWidth)
      end

      -- Resize positioner to keep frames centered
      newWidth = (#frames > 0) and Tools:Measure(self.Frame, frames[1],
        frames[#frames], "LEFT", "RIGHT") or 1
      ui.OptionsPositioner:SetWidth(newWidth)
    end
  end
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

function DejunkChildOptionsFrame:CreateOptions()
  local ui = self.UI

  ui.OptionsPositioner = FrameFactory:CreateTexture(self.Frame)
  ui.OptionsPositioner:ClearAllPoints()
  ui.OptionsPositioner:SetPoint("TOP")

  ui.GeneralOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(self.Frame, L.GENERAL_TEXT, "GameFontNormal")
  ui.GeneralOptionsFrame:SetPoint("TOPLEFT", ui.OptionsPositioner)
  self.OptionFrames[1] = ui.GeneralOptionsFrame

  ui.SellOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(self.Frame, L.SELL_TEXT, "GameFontNormal")
  ui.SellOptionsFrame:SetPoint("TOPLEFT", ui.GeneralOptionsFrame, "TOPRIGHT", Tools:Padding(), 0)
  self.OptionFrames[2] = ui.SellOptionsFrame

  ui.IgnoreOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(self.Frame, L.IGNORE_TEXT, "GameFontNormal")
  ui.IgnoreOptionsFrame:SetPoint("TOPLEFT", ui.SellOptionsFrame, "TOPRIGHT", Tools:Padding(), 0)
  self.OptionFrames[3] = ui.IgnoreOptionsFrame

  self:PopulateGeneralOptions()
  self:PopulateSellOptions()
  self:PopulateIgnoreOptions()
end

function DejunkChildOptionsFrame:PopulateGeneralOptions()
  local add = function(option)
    self.UI.GeneralOptionsFrame:AddOption(option)
  end

  -- Auto sell
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.AUTO_SELL_TEXT, nil, L.AUTO_SELL_TOOLTIP, DejunkDB.AutoSell))

  -- Auto repair
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.AUTO_REPAIR_TEXT, Colors.LabelText, L.AUTO_REPAIR_TOOLTIP, DejunkDB.AutoRepair))

  -- Safe mode
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.SAFE_MODE_TEXT, Colors.LabelText, L.SAFE_MODE_TOOLTIP, DejunkDB.SafeMode))

  -- Silent mode
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.SILENT_MODE_TEXT, Colors.LabelText, L.SILENT_MODE_TOOLTIP, DejunkDB.SilentMode))
end

function DejunkChildOptionsFrame:PopulateSellOptions()
  local add = function(option)
    self.UI.SellOptionsFrame:AddOption(option)
  end

  -- By Quality text
  local byQuality = FrameFactory:CreateFontString(self.UI.SellOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  byQuality:SetText(L.BY_QUALITY_TEXT)
  add(byQuality)

  -- Sell by quality check buttons
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.POOR_TEXT, Colors.Poor, L.SELL_ALL_TOOLTIP, DejunkDB.SellPoor))

  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.COMMON_TEXT, Colors.Common, L.SELL_ALL_TOOLTIP, DejunkDB.SellCommon))

  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.UNCOMMON_TEXT, Colors.Uncommon, L.SELL_ALL_TOOLTIP, DejunkDB.SellUncommon))

  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.RARE_TEXT, Colors.Rare, L.SELL_ALL_TOOLTIP, DejunkDB.SellRare))

  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.EPIC_TEXT, Colors.Epic, L.SELL_ALL_TOOLTIP, DejunkDB.SellEpic))

  -- By Type text
  local byType = FrameFactory:CreateFontString(self.UI.SellOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  byType:SetText(L.BY_TYPE_TEXT)
  add(byType)

  -- Unsuitable Equipment
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.SELL_UNSUITABLE_TEXT, nil, L.SELL_UNSUITABLE_TOOLTIP, DejunkDB.SellUnsuitable))

  -- Equipment below ilvl
  add(FrameFactory:CreateCheckButtonNumberBox(nil, "Small",
    L.SELL_EQUIPMENT_BELOW_ILVL_TEXT, nil, L.SELL_EQUIPMENT_BELOW_ILVL_TOOLTIP,
    DejunkDB.SellEquipmentBelowILVL))
  --]]
end

function DejunkChildOptionsFrame:PopulateIgnoreOptions()
  local add = function(option)
    self.UI.IgnoreOptionsFrame:AddOption(option)
  end

  -- By Type text
  local byType = FrameFactory:CreateFontString(self.UI.IgnoreOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  byType:SetText(L.BY_TYPE_TEXT)
  add(byType)

  -- Battle Pets
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_BATTLEPETS_TEXT, Colors.LabelText, L.IGNORE_BATTLEPETS_TOOLTIP, DejunkDB.IgnoreBattlePets))
  -- Consumables
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_CONSUMABLES_TEXT, Colors.LabelText, L.IGNORE_CONSUMABLES_TOOLTIP, DejunkDB.IgnoreConsumables))
  -- Gems
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_GEMS_TEXT, Colors.LabelText, L.IGNORE_GEMS_TOOLTIP, DejunkDB.IgnoreGems))
  -- Glyphs
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_GLYPHS_TEXT, Colors.LabelText, L.IGNORE_GLYPHS_TOOLTIP, DejunkDB.IgnoreGlyphs))
  -- Item Enhancements
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_ITEM_ENHANCEMENTS_TEXT, Colors.LabelText, L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP, DejunkDB.IgnoreItemEnhancements))
  -- Recipes
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_RECIPES_TEXT, Colors.LabelText, L.IGNORE_RECIPES_TOOLTIP, DejunkDB.IgnoreRecipes))
  -- Trade Goods
  add(FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_TRADE_GOODS_TEXT, Colors.LabelText, L.IGNORE_TRADE_GOODS_TOOLTIP, DejunkDB.IgnoreTradeGoods))
end
