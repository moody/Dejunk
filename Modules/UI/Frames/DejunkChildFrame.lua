-- DejunkChildFrame: displays options for dejunking.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL

local DFL = Addon.Libs.DFL
local Factory = DFL.Factory
local Tools = DFL.Tools

-- Upvalues
local nop = nop

-- Dejunk
local DejunkChildFrame = Addon.Frames.DejunkChildFrame

-- local Colors = Addon.Colors
local DejunkDB = Addon.DejunkDB

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function DejunkChildFrame:OnInitialize()
  local frame = self.Frame
  frame:SetFlexible(true)
  frame:SetSpacing(Tools:Padding())
  
  self:CreateGeneralOptions()
  self:CreateSellOptions()
  self:CreateIgnoreOptions()

  self.CreateGeneralOptions = nil
  self.CreateSellOptions = nil
  self.CreateIgnoreOptions = nil
end

-- ============================================================================
-- Creation Functions
-- ============================================================================

local function createHeading(text)
  local heading = Factory.FontString:Create(UIParent, nil, "GameFontNormalSmall", text)
  -- heading:SetColors(Colors.LabelText)
  return heading
end

local function createCheckButton(text, tooltip, svKey)
  local cb = Factory.CheckButton:Create(UIParent, "GameFontNormalSmall", text, tooltip)
  cb:SetCheckRefreshFunction(function() return DejunkDB.SV[svKey] end)
  -- cb:SetColors(Colors.LabelText, Colors.ParentFrame)
  function cb:OnClick(checked) DejunkDB.SV[svKey] = checked end
  -- Tools:AddBorder(cb._checkButton, unpack(Colors.ScrollFrame))
  return cb
end

local function createScrollFrame(title)
  local frame = DejunkChildFrame.Frame
  local container = Factory.Container:Create(frame, Factory.Alignments.TOP, Factory.Directions.COLUMN)
  container:SetSpacing(Tools:Padding(0.5))
  frame:Add(container)
  -- Title
  local titleFS = Factory.FontString:Create(container, nil, "GameFontNormal", title)
  -- titleFS:SetColors(Colors.LabelText)
  container:Add(titleFS)
  -- Scroll frame
  local sf = Factory.SliderScrollFrame:Create(container)
  -- sf:SetColors(Colors.ScrollFrame, {
  --   Colors.Slider,
  --   Colors.SliderThumb,
  --   Colors.SliderThumbHi
  -- })
  sf:SetMinWidth(150)
  sf:SetMinHeight(100)
  container:Add(sf)
  return sf
end

function DejunkChildFrame:CreateGeneralOptions()
  local sf = createScrollFrame(L.OPTIONS_TEXT)
  
  -- General heading
  sf:Add(createHeading(L.GENERAL_TEXT))
  -- Silent mode
  sf:Add(createCheckButton(L.SILENT_MODE_TEXT, L.SILENT_MODE_TOOLTIP, "SilentMode"))
  -- Verbose mode
  sf:Add(createCheckButton(L.VERBOSE_MODE_TEXT, L.VERBOSE_MODE_TOOLTIP, "VerboseMode"))

  -- Selling heading
  sf:Add(createHeading(L.SELLING_TEXT))
  -- Auto sell
  sf:Add(createCheckButton(L.AUTO_SELL_TEXT, L.AUTO_SELL_TOOLTIP, "AutoSell"))
  -- Safe mode
  sf:Add(createCheckButton(L.SAFE_MODE_TEXT, format(L.SAFE_MODE_TOOLTIP, Addon.Consts.SAFE_MODE_MAX), "SafeMode"))

  -- Repairing heading
  sf:Add(createHeading(L.REPAIRING_TEXT))
  -- Auto repair
  sf:Add(createCheckButton(L.AUTO_REPAIR_TEXT, L.AUTO_REPAIR_TOOLTIP, "AutoRepair"))
  -- Use guild repair
  sf:Add(createCheckButton(L.USE_GUILD_REPAIR_TEXT, L.USE_GUILD_REPAIR_TOOLTIP, "UseGuildRepair"))
end

function DejunkChildFrame:CreateSellOptions()
  local sf = createScrollFrame(L.SELL_TEXT)

  -- By quality heading
  sf:Add(createHeading(L.BY_QUALITY_TEXT))
  -- Sell by quality check buttons
  local poor = createCheckButton(L.POOR_TEXT, L.SELL_ALL_TOOLTIP, "SellPoor")
  local common = createCheckButton(L.COMMON_TEXT, L.SELL_ALL_TOOLTIP, "SellCommon")
  local uncommon = createCheckButton(L.UNCOMMON_TEXT, L.SELL_ALL_TOOLTIP, "SellUncommon")
  local rare = createCheckButton(L.RARE_TEXT, L.SELL_ALL_TOOLTIP, "SellRare")
  local epic = createCheckButton(L.EPIC_TEXT, L.SELL_ALL_TOOLTIP, "SellEpic")
  
  poor:SetColors(DCL.WowColors.Poor)
  common:SetColors(DCL.WowColors.Common)
  uncommon:SetColors(DCL.WowColors.Uncommon)
  rare:SetColors(DCL.WowColors.Rare)
  epic:SetColors(DCL.WowColors.Epic)
  
  sf:Add(poor)
  sf:Add(common)
  sf:Add(uncommon)
  sf:Add(rare)
  sf:Add(epic)

  -- By Type heading
  sf:Add(createHeading(L.BY_TYPE_TEXT))
  -- Unsuitable Equipment
  sf:Add(createCheckButton(L.SELL_UNSUITABLE_TEXT,
    L.SELL_UNSUITABLE_TOOLTIP, "SellUnsuitable"))
  -- -- Equipment below ilvl
  -- sf:Add(createCheckButtonNumberBox(L.SELL_EQUIPMENT_BELOW_ILVL_TEXT,
  --   L.SELL_EQUIPMENT_BELOW_ILVL_TOOLTIP, "SellEquipmentBelowILVL"))
end

function DejunkChildFrame:CreateIgnoreOptions()
  local sf = createScrollFrame(L.IGNORE_TEXT)

  -- By category heading
  sf:Add(createHeading(L.BY_CATEGORY_TEXT))
  -- Battle Pets
  sf:Add(createCheckButton(L.IGNORE_BATTLEPETS_TEXT, L.IGNORE_BATTLEPETS_TOOLTIP, "IgnoreBattlePets"))
  -- Consumables
  sf:Add(createCheckButton(L.IGNORE_CONSUMABLES_TEXT, L.IGNORE_CONSUMABLES_TOOLTIP, "IgnoreConsumables"))
  -- Gems
  sf:Add(createCheckButton(L.IGNORE_GEMS_TEXT, L.IGNORE_GEMS_TOOLTIP, "IgnoreGems"))
  -- Glyphs
  sf:Add(createCheckButton(L.IGNORE_GLYPHS_TEXT, L.IGNORE_GLYPHS_TOOLTIP, "IgnoreGlyphs"))
  -- Item Enhancements
  sf:Add(createCheckButton(L.IGNORE_ITEM_ENHANCEMENTS_TEXT, L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP, "IgnoreItemEnhancements"))
  -- Recipes
  sf:Add(createCheckButton(L.IGNORE_RECIPES_TEXT, L.IGNORE_RECIPES_TOOLTIP, "IgnoreRecipes"))
  -- Trade Goods
  sf:Add(createCheckButton(L.IGNORE_TRADE_GOODS_TEXT, L.IGNORE_TRADE_GOODS_TOOLTIP, "IgnoreTradeGoods"))

  -- By Type heading
  sf:Add(createHeading(L.BY_TYPE_TEXT))
  -- Binds when equipped
  sf:Add(createCheckButton(L.IGNORE_BOE_TEXT, L.IGNORE_BOE_TOOLTIP, "IgnoreBindsWhenEquipped"))
  -- Cosmetic
  sf:Add(createCheckButton(L.IGNORE_COSMETIC_TEXT, L.IGNORE_COSMETIC_TOOLTIP, "IgnoreCosmetic"))
  -- Equipment Sets
  sf:Add(createCheckButton(L.IGNORE_EQUIPMENT_SETS_TEXT, L.IGNORE_EQUIPMENT_SETS_TOOLTIP, "IgnoreEquipmentSets"))
  -- Soulbound
  sf:Add(createCheckButton(L.IGNORE_SOULBOUND_TEXT, L.IGNORE_SOULBOUND_TOOLTIP, "IgnoreSoulbound"))
  -- Tradeable
  sf:Add(createCheckButton(L.IGNORE_TRADEABLE_TEXT, L.IGNORE_TRADEABLE_TOOLTIP, "IgnoreTradeable"))
end
