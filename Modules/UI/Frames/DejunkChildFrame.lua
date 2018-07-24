-- DejunkChildFrame: displays options for dejunking.

local AddonName, Addon = ...

-- Libs
local L = Addon.Libs.L
local DCL = Addon.Libs.DCL
local DFL = Addon.Libs.DFL

-- Upvalues
local nop = nop

-- Dejunk
local DejunkChildFrame = Addon.Frames.DejunkChildFrame

local Colors = Addon.Colors
local DejunkDB = Addon.DejunkDB
local Tools = Addon.Tools

-- ============================================================================
-- Frame Lifecycle Functions
-- ============================================================================

function DejunkChildFrame:OnInitialize()
  local frame = self.Frame
  frame:SetDirection(DFL.Directions.DOWN)
  frame:SetSpacing(DFL:Padding(0.5))
  
  self:CreateOptions()
  self:CreateLists()

  self.CreateOptions = nil
  self.CreateLists = nil
end

-- ============================================================================
-- Options Creation Functions
-- ============================================================================

do
  local function createCheckButton(text, tooltip, svKey)
    local cb = DFL.CheckButton:Create(UIParent, text, tooltip, DFL.Fonts.Small)
    cb:SetCheckRefreshFunction(function() return DejunkDB:Get(svKey) end)
    cb:SetColors(Colors.LabelText, Colors.ParentFrame, Colors.ScrollFrame)
    function cb:OnClick(checked)
      DejunkDB:Set(svKey, checked)
      Addon.EventManager:Emit("OnOptionChanged", svKey)
    end
    return cb
  end

  local function createGeneralOptions()
    local sf = Addon.Objects.OptionsFrame:Create(DejunkChildFrame.Frame, L.OPTIONS_TEXT)
    
    do -- General
      local general = sf:CreateHeading(L.GENERAL_TEXT)
      -- Silent mode
      general:Add(createCheckButton(L.SILENT_MODE_TEXT, L.SILENT_MODE_TOOLTIP, "SilentMode"))
      -- Verbose mode
      general:Add(createCheckButton(L.VERBOSE_MODE_TEXT, L.VERBOSE_MODE_TOOLTIP, "VerboseMode"))
    end

    do -- Selling
      local selling = sf:CreateHeading(L.SELLING_TEXT)
      -- Auto sell
      selling:Add(createCheckButton(L.AUTO_SELL_TEXT, L.AUTO_SELL_TOOLTIP, "AutoSell"))
      -- Safe mode
      selling:Add(createCheckButton(L.SAFE_MODE_TEXT, format(L.SAFE_MODE_TOOLTIP, Addon.Consts.SAFE_MODE_MAX), "SafeMode"))
    end

    do -- Repairing
      local repairing = sf:CreateHeading(L.REPAIRING_TEXT)
      -- Auto repair
      repairing:Add(createCheckButton(L.AUTO_REPAIR_TEXT, L.AUTO_REPAIR_TOOLTIP, "AutoRepair"))
      -- Use guild repair
      repairing:Add(createCheckButton(L.USE_GUILD_REPAIR_TEXT, L.USE_GUILD_REPAIR_TOOLTIP, "UseGuildRepair"))
    end

    return sf
  end

  local function createSellOptions()
    local sf = Addon.Objects.OptionsFrame:Create(DejunkChildFrame.Frame, L.SELL_TEXT)

    do -- By Quality
      local byQuality = sf:CreateHeading(L.BY_QUALITY_TEXT)
      -- Sell by quality check buttons
      local poor = createCheckButton(L.POOR_TEXT, L.SELL_ALL_TOOLTIP, "SellPoor")
      local common = createCheckButton(L.COMMON_TEXT, L.SELL_ALL_TOOLTIP, "SellCommon")
      local uncommon = createCheckButton(L.UNCOMMON_TEXT, L.SELL_ALL_TOOLTIP, "SellUncommon")
      local rare = createCheckButton(L.RARE_TEXT, L.SELL_ALL_TOOLTIP, "SellRare")
      local epic = createCheckButton(L.EPIC_TEXT, L.SELL_ALL_TOOLTIP, "SellEpic")
      
      poor:SetColors(DCL.Wow.Poor)
      common:SetColors(DCL.Wow.Common)
      uncommon:SetColors(DCL.Wow.Uncommon)
      rare:SetColors(DCL.Wow.Rare)
      epic:SetColors(DCL.Wow.Epic)
      
      byQuality:Add(poor)
      byQuality:Add(common)
      byQuality:Add(uncommon)
      byQuality:Add(rare)
      byQuality:Add(epic)
    end

    do -- By Type
      local byType = sf:CreateHeading(L.BY_TYPE_TEXT)
      -- Unsuitable Equipment
      byType:Add(createCheckButton(L.SELL_UNSUITABLE_TEXT,
        L.SELL_UNSUITABLE_TOOLTIP, "SellUnsuitable"))
      -- Below Average Item Level
      byType:Add(createCheckButton(
        L.SELL_BELOW_AVERAGE_ILVL_TEXT,
        L.SELL_BELOW_AVERAGE_ILVL_TOOLTIP,
        "SellBelowAverageILVL.Enabled")
      )
      do
        local f = DFL.Frame:Create(byType, DFL.Alignments.CENTER)
        f:SetSpacing(DFL:Padding(0.5))
        
        local minLabel = DFL.FontString:Create(f, "0")
        minLabel:SetColors(Colors.LabelText)
        f:Add(minLabel)

        local slider = DFL.Slider:Create(f)
        slider:SetColors(Colors.Slider, Colors.SliderThumb, Colors.SliderThumbHi)
        slider:SetOrientation(DFL.Orientations.HORIZONTAL)
        slider:SetWidth(100)
        slider:SetMinMaxValues(0, 100)
        slider:SetValueStep(1)
        slider:SetShowTooltip(true)
        function slider:OnValueChanged(value)
          DejunkDB:Set("SellBelowAverageILVL.Value", value)
        end
        f:Add(slider)
        
        local maxLabel = DFL.FontString:Create(f, "100")
        maxLabel:SetColors(Colors.LabelText)
        f:Add(maxLabel)
        
        byType:Add(f)
      end
    end

    return sf
  end

  local function createIgnoreOptions()
    local sf = Addon.Objects.OptionsFrame:Create(DejunkChildFrame.Frame, L.IGNORE_TEXT)

    do -- By Category
      local byCategory = sf:CreateHeading(L.BY_CATEGORY_TEXT)
      -- Battle Pets
      byCategory:Add(createCheckButton(L.IGNORE_BATTLEPETS_TEXT, L.IGNORE_BATTLEPETS_TOOLTIP, "IgnoreBattlePets"))
      -- Consumables
      byCategory:Add(createCheckButton(L.IGNORE_CONSUMABLES_TEXT, L.IGNORE_CONSUMABLES_TOOLTIP, "IgnoreConsumables"))
      -- Gems
      byCategory:Add(createCheckButton(L.IGNORE_GEMS_TEXT, L.IGNORE_GEMS_TOOLTIP, "IgnoreGems"))
      -- Glyphs
      byCategory:Add(createCheckButton(L.IGNORE_GLYPHS_TEXT, L.IGNORE_GLYPHS_TOOLTIP, "IgnoreGlyphs"))
      -- Item Enhancements
      byCategory:Add(createCheckButton(L.IGNORE_ITEM_ENHANCEMENTS_TEXT, L.IGNORE_ITEM_ENHANCEMENTS_TOOLTIP, "IgnoreItemEnhancements"))
      -- Recipes
      byCategory:Add(createCheckButton(L.IGNORE_RECIPES_TEXT, L.IGNORE_RECIPES_TOOLTIP, "IgnoreRecipes"))
      -- Trade Goods
      byCategory:Add(createCheckButton(L.IGNORE_TRADE_GOODS_TEXT, L.IGNORE_TRADE_GOODS_TOOLTIP, "IgnoreTradeGoods"))
    end

    do -- By Type
      local byType = sf:CreateHeading(L.BY_TYPE_TEXT)
      -- Binds when equipped
      byType:Add(createCheckButton(L.IGNORE_BOE_TEXT, L.IGNORE_BOE_TOOLTIP, "IgnoreBindsWhenEquipped"))
      -- Cosmetic
      byType:Add(createCheckButton(L.IGNORE_COSMETIC_TEXT, L.IGNORE_COSMETIC_TOOLTIP, "IgnoreCosmetic"))
      -- Equipment Sets
      byType:Add(createCheckButton(L.IGNORE_EQUIPMENT_SETS_TEXT, L.IGNORE_EQUIPMENT_SETS_TOOLTIP, "IgnoreEquipmentSets"))
      -- Soulbound
      byType:Add(createCheckButton(L.IGNORE_SOULBOUND_TEXT, L.IGNORE_SOULBOUND_TOOLTIP, "IgnoreSoulbound"))
      -- Tradeable
      byType:Add(createCheckButton(L.IGNORE_TRADEABLE_TEXT, L.IGNORE_TRADEABLE_TOOLTIP, "IgnoreTradeable"))
    end

    return sf
  end

  local function createDestroyOptions()
    local sf = Addon.Objects.OptionsFrame:Create(DejunkChildFrame.Frame, L.DESTROY_TEXT)
    
    do -- General
      local general = sf:CreateHeading(L.GENERAL_TEXT)
      -- Auto destroy
      general:Add(createCheckButton(
        L.AUTO_DESTROY_TEXT,
        L.AUTO_DESTROY_TOOLTIP,
        "AutoDestroy")
      )
      -- Price threshold check button and currency input
      general:Add(createCheckButton(
        L.PRICE_THRESHOLD_TEXT,
        L.PRICE_THRESHOLD_TOOLTIP,
        "DestroyUsePriceThreshold")
      )
      general:Add(Addon.Objects.CurrencyField:Create(
        general,
        "DestroyPriceThreshold",
        DFL.Fonts.Small)
      )
    end

    do -- Destroy
      local destroy = sf:CreateHeading(L.DESTROY_TEXT)
      
      -- Destroy poor
      local poor = createCheckButton(
        L.POOR_TEXT,
        L.DESTROY_ALL_TOOLTIP,
        "DestroyPoor"
      )
      poor:SetColors(DCL.Wow.Poor)
      destroy:Add(poor)
      
      -- Destroy Inclusions
      local inclusions = createCheckButton(
        L.INCLUSIONS_TEXT,
        format(L.DESTROY_LIST_TOOLTIP, Tools:GetInclusionsString()),
        "DestroyInclusions"
      )
      inclusions:SetColors(Colors.Inclusions)
      destroy:Add(inclusions)
      
      -- Destroy pets already collected
      destroy:Add(createCheckButton(
        L.DESTROY_PETS_ALREADY_COLLECTED_TEXT,
        L.DESTROY_PETS_ALREADY_COLLECTED_TOOLTIP,
        "DestroyPetsAlreadyCollected")
      )
      
      -- Destroy toys already collected
      destroy:Add(createCheckButton(
        L.DESTROY_TOYS_ALREADY_COLLECTED_TEXT,
        L.DESTROY_TOYS_ALREADY_COLLECTED_TOOLTIP,
        "DestroyToysAlreadyCollected")
      )
    end
    
    do -- Ignore
      local ignore = sf:CreateHeading(L.IGNORE_TEXT)
      
     -- Ignore Exclusions
      local exclusions = createCheckButton(
        L.EXCLUSIONS_TEXT,
        format(L.DESTROY_IGNORE_LIST_TOOLTIP, Tools:GetExclusionsString()),
        "DestroyIgnoreExclusions"
      )
      exclusions:SetColors(Colors.Exclusions)
      ignore:Add(exclusions)
    end

    return sf
  end

  function DejunkChildFrame:CreateOptions()
    local frame = DFL.Frame:Create(self.Frame)
    frame:SetLayout(DFL.Layouts.FILL)
    frame:SetSpacing(DFL:Padding(0.5))
    frame:Add(createGeneralOptions())
    frame:Add(createSellOptions())
    frame:Add(createIgnoreOptions())
    frame:Add(createDestroyOptions())
    self.Frame:Add(frame)
  end
end

-- ============================================================================
-- Lists Creation Function
-- ============================================================================

function DejunkChildFrame:CreateLists()
  local parent = self.Frame
  local frame = DFL.Frame:Create(parent)
  frame:SetLayout(DFL.Layouts.FLEX)
  frame:SetSpacing(DFL:Padding(0.5))
  frame:Add(Addon.Objects.ListFrame:Create(parent, Addon.ListManager.Inclusions))
  frame:Add(Addon.Objects.ListFrame:Create(parent, Addon.ListManager.Exclusions))
  frame:Add(Addon.Objects.ListFrame:Create(parent, Addon.ListManager.Destroyables))
  parent:Add(frame)
end
