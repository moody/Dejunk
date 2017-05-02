--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

-- Dejunk_BasicOptionsFrame: displays a simple options menu.

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local BasicOptionsFrame = DJ.DejunkFrames.BasicOptionsFrame

local Colors = DJ.Colors
local Tools = DJ.Tools
local DejunkDB = DJ.DejunkDB
local FrameFactory = DJ.FrameFactory

-- Variables
BasicOptionsFrame.Frames = {}
local ui = BasicOptionsFrame.UI

--[[
//*******************************************************************
//                       Init/Deinit Functions
//*******************************************************************
--]]

-- @Override
function BasicOptionsFrame:OnInitialize()
  self:CreateOptions()
end

-- @Override
function BasicOptionsFrame:OnDeinitialize()
  for k in pairs(self.Frames) do self.Frames[k] = nil end
end

--[[
//*******************************************************************
//                       General Frame Functions
//*******************************************************************
--]]

function BasicOptionsFrame:Resize()
  local newWidth = 0
  local newHeight = 0

  -- Get largest width and height of options frames
  for i, v in ipairs(self.Frames) do
    v:Resize()
    newWidth = max(newWidth, v:GetWidth())
    newHeight = max(newHeight, v:GetHeight())
  end

  -- Even the sizes of the frames
  for i, v in ipairs(self.Frames) do
    v:SetWidth(newWidth)
    v:SetHeight(newHeight)
  end

  -- Resize positioner to keep frames centered
  newWidth = Tools:Measure(ui.Frame, self.Frames[1],
    self.Frames[#self.Frames], "LEFT", "RIGHT")
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
  local setWidth = BasicOptionsFrame.SetWidth

  function BasicOptionsFrame:SetWidth(width)
    local oldWidth = self:GetWidth()
    setWidth(self, width)

    if (width > oldWidth) then -- resize options frames
      local pad = Tools:Padding(2) + ((#self.Frames - 1) * Tools:Padding());
      local newWidth = ((width - pad) / #self.Frames)

      -- Even the widths of the frames
      for i, v in ipairs(self.Frames) do
        v:SetWidth(newWidth) end

      -- Resize positioner to keep frames centered
      newWidth = Tools:Measure(ui.Frame,
        self.Frames[1], self.Frames[#self.Frames], "LEFT", "RIGHT")
      ui.OptionsPositioner:SetWidth(newWidth)
    end
  end
end

--[[
//*******************************************************************
//                       UI Creation Functions
//*******************************************************************
--]]

function BasicOptionsFrame:CreateOptions()
  ui.OptionsPositioner = FrameFactory:CreateTexture(ui.Frame)
  ui.OptionsPositioner:ClearAllPoints()
  ui.OptionsPositioner:SetPoint("TOP")

  self:CreateGeneralOptions()
  self:CreateSellOptions()
  self:CreateIgnoreOptions()
end

function BasicOptionsFrame:CreateGeneralOptions()
  ui.GeneralOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(ui.Frame, L.GENERAL_TEXT, "GameFontNormal")
  ui.GeneralOptionsFrame:SetPoint("TOPLEFT", ui.OptionsPositioner)
  self.Frames[#self.Frames+1] = ui.GeneralOptionsFrame

  local options = {}

  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.AUTO_SELL_TEXT, nil, L.AUTO_SELL_TOOLTIP, DejunkDB.AutoSell)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.AUTO_REPAIR_TEXT, Colors.LabelText, L.AUTO_REPAIR_TOOLTIP, DejunkDB.AutoRepair)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.SAFE_MODE_TEXT, Colors.LabelText, L.SAFE_MODE_TOOLTIP, DejunkDB.SafeMode)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.SILENT_MODE_TEXT, Colors.LabelText, L.SILENT_MODE_TOOLTIP, DejunkDB.SilentMode)

  for i=1, #options do
    ui.GeneralOptionsFrame:AddOption(options[i])
  end
end

function BasicOptionsFrame:CreateSellOptions()
  ui.SellOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(ui.Frame, L.SELL_TEXT, "GameFontNormal")
  ui.SellOptionsFrame:SetPoint("TOPLEFT", ui.GeneralOptionsFrame, "TOPRIGHT", Tools:Padding(), 0)
  self.Frames[#self.Frames+1] = ui.SellOptionsFrame

  local options = {}

  -- By Quality text
  options[#options+1] = FrameFactory:CreateFontString(ui.SellOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  options[#options]:SetText(L.BY_QUALITY_TEXT)

  -- Sell by quality check buttons
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.POOR_TEXT, Colors.Poor, L.SELL_ALL_TOOLTIP, DejunkDB.SellPoor)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.COMMON_TEXT, Colors.Common, L.SELL_ALL_TOOLTIP, DejunkDB.SellCommon)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.UNCOMMON_TEXT, Colors.Uncommon, L.SELL_ALL_TOOLTIP, DejunkDB.SellUncommon)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.RARE_TEXT, Colors.Rare, L.SELL_ALL_TOOLTIP, DejunkDB.SellRare)
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.EPIC_TEXT, Colors.Epic, L.SELL_ALL_TOOLTIP, DejunkDB.SellEpic)

  -- By Type text
  options[#options+1] = FrameFactory:CreateFontString(ui.SellOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  options[#options]:SetText(L.BY_TYPE_TEXT)

  -- Unsuitable Equipment
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.SELL_UNSUITABLE_TEXT, nil, L.SELL_UNSUITABLE_TOOLTIP, DejunkDB.SellUnsuitable)

  -- Equipment below ilvl
  options[#options+1] = FrameFactory:CreateCheckButtonNumberBox(nil, "Small",
    L.SELL_EQUIPMENT_BELOW_ILVL_TEXT, nil, L.SELL_EQUIPMENT_BELOW_ILVL_TOOLTIP, DejunkDB.SellEquipmentBelowILVL)

  for i=1, #options do
    ui.SellOptionsFrame:AddOption(options[i])
  end
end

function BasicOptionsFrame:CreateIgnoreOptions()
  ui.IgnoreOptionsFrame = FrameFactory:CreateScrollingOptionsFrame(ui.Frame, L.IGNORE_TEXT, "GameFontNormal")
  ui.IgnoreOptionsFrame:SetPoint("TOPLEFT", ui.SellOptionsFrame, "TOPRIGHT", Tools:Padding(), 0)
  self.Frames[#self.Frames+1] = ui.IgnoreOptionsFrame

  local options = {}

  -- By Classification text
  options[#options+1] = FrameFactory:CreateFontString(ui.SellOptionsFrame,
    nil, "GameFontNormalSmall", Colors.LabelText)
  options[#options]:SetText(L.BY_TYPE_TEXT)

  -- Battle Pets
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_BATTLEPETS_TEXT, Colors.LabelText, L.IGNORE_BATTLEPETS_TOOLTIP, DejunkDB.IgnoreBattlePets)
  -- Consumables
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_CONSUMABLES_TEXT, Colors.LabelText, L.IGNORE_CONSUMABLES_TOOLTIP, DejunkDB.IgnoreConsumables)
  -- Gems
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_GEMS_TEXT, Colors.LabelText, L.IGNORE_GEMS_TOOLTIP, DejunkDB.IgnoreGems)
  -- Glyphs
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_GLYPHS_TEXT, Colors.LabelText, L.IGNORE_GLYPHS_TOOLTIP, DejunkDB.IgnoreGlyphs)
  -- Item Enhancements
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_ITEM_ENHANCEMENTS_TEXT, Colors.LabelText, L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP, DejunkDB.IgnoreItemEnhancements)
  -- Recipes
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_RECIPES_TEXT, Colors.LabelText, L.IGNORE_RECIPES_TOOLTIP, DejunkDB.IgnoreRecipes)
  -- Trade Goods
  options[#options+1] = FrameFactory:CreateCheckButton(nil, "Small",
    L.IGNORE_TRADE_GOODS_TEXT, Colors.LabelText, L.IGNORE_TRADE_GOODS_TOOLTIP, DejunkDB.IgnoreTradeGoods)

  for i=1, #options do
    ui.IgnoreOptionsFrame:AddOption(options[i])
  end
end
