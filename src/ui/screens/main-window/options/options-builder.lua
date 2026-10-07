local Addon = select(2, ...) ---@type Addon
local Coins = Addon:GetModule("Coins")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local EquipmentTypes = Addon:GetModule("EquipmentTypes")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class OptionsBuilder
local OptionsBuilder = Addon:GetModule("OptionsBuilder")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class OptionsBuilderPanelOptions : TitledPanelComponentOptions
--- @field descriptionText? string Small grey text above the first group, followed by a divider.

--- @class OptionsBuilderTextOptions
--- @field labelText string Option name.
--- @field descriptionText string Shown in grey below the label.
--- @field warningText? string Shown in pink below the description.
--- @field ignoresSpecialEquipment? boolean Marks the label with an asterisk explained by `AddSpecialEquipmentFootnote()`.

--- @class OptionsBuilderCardOptions : OptionCardOptions, OptionsBuilderTextOptions

--- @class OptionsBuilderChoice
--- @field value any Value selected by this choice's chip.
--- @field text string Chip label.

-- ============================================================================
-- Local Functions
-- ============================================================================

--- The containers that have a group, so a later group gets a divider above it.
--- @type table<WaffleFlexComponent, boolean?>
local groupedContainers = setmetatable({}, { __mode = "k" })

--- Adds a line of chips to the box where exactly one is checked: the one whose
--- value `get()` returns. Clicking a chip selects its value.
--- @param self OptionsBuilderSettingsBox
--- @param labelText string
--- @param choices OptionsBuilderChoice[]
--- @param get fun(): any
--- @param set fun(value: any)
local function addChoiceLine(self, labelText, choices, get, set)
  local chips = {}

  for _, choice in ipairs(choices) do
    chips[#chips + 1] = {
      text = choice.text,
      get = function() return get() == choice.value end,
      set = function(checked) if checked then set(choice.value) end end
    }
  end

  self:AddLine(labelText):AttachComponent(ComponentFactory:CheckChipGroup({ chips = chips }))
end

--- Attaches a number input to the line, passing the mouse through while disabled.
--- @param line WaffleFlexComponent
--- @param options NumberInputComponentOptions
--- @return WaffleFlexComponent input
local function attachNumberInput(line, options)
  local input = line:AttachComponent(ComponentFactory:NumberInput(options))

  input:WhenFrameReady(function(frame)
    --- @cast frame NumberInputWidget
    frame:PropagateWhenDisabled(true)
  end)

  return input
end

--- Adds an editable item level line to the box for a setting's `value` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): ItemLevelOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addItemLevelLine(self, getState, mergeAction)
  attachNumberInput(self:AddLine(L.ITEM_LEVEL), {
    get = function() return getState().value end,
    set = function(value) StateManager:Dispatch(mergeAction({ value = value })) end
  })
end

--- The inputs of a price line, each with its coin icon. Each index matches the value at that position in
--- the return values of `Coins:Split()`: gold, silver, copper.
local PRICE_COINS = {
  { icon = "|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:0:0|t", width = 70, maxLetters = 6 },
  { icon = "|TInterface\\MoneyFrame\\UI-SilverIcon:0:0:0:0|t", width = 40, maxLetters = 2 },
  { icon = "|TInterface\\MoneyFrame\\UI-CopperIcon:0:0:0:0|t", width = 40, maxLetters = 2 }
}

--- Adds gold, silver, and copper inputs to the box for a setting's `value` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): PriceOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addPriceLine(self, getState, mergeAction)
  local line = self:AddLine(L.PRICE)
  local editBoxes = {} --- @type NumberInputWidget[]

  for index, coin in ipairs(PRICE_COINS) do
    local input = attachNumberInput(line, {
      width = coin.width,
      maxLetters = coin.maxLetters,
      get = function() return select(index, Coins:Split(getState().value)) end,
      set = function(value)
        local parts = { Coins:Split(getState().value) }
        parts[index] = value
        StateManager:Dispatch(mergeAction({ value = Coins:Combine(unpack(parts)) }))
      end
    })

    -- Tab and Shift+Tab move between the inputs.
    input:WhenFrameReady(function(frame)
      --- @cast frame NumberInputWidget
      editBoxes[index] = frame
      frame:SetScript("OnTabPressed", function()
        local step = IsShiftKeyDown() and -1 or 1
        editBoxes[(index - 1 + step) % #PRICE_COINS + 1]:SetFocus()
      end)
    end)

    local icon = line:AttachComponent(ComponentFactory:Text({ text = coin.icon, width = "AUTO" }))
    icon:SetMarginTop(Widgets.CONTROL_PADDING)
  end
end

--- Adds a line of chips to the box for what a setting applies to: selling, destroying, or both.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): ItemFilterScope Returns the setting's current scope.
--- @param setState fun(scope: ItemFilterScope) Receives the scope the user picks.
local function addAppliesToLine(self, getState, setState)
  local choices = {
    { value = "SELL", text = L.SELLING },
    { value = "DESTROY", text = L.DESTROYING },
    { value = "BOTH", text = L.BOTH }
  }

  self:AddChoiceLine(L.APPLIES_TO, choices, getState, setState)
end

--- Adds a qualities line to the box for a setting's `qualities` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): QualitiesOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addQualitiesLine(self, getState, mergeAction)
  self:AddLine(L.QUALITIES):AttachComponent(ComponentFactory:QualityToggles({
    get = function(quality) return getState().qualities[quality] end,
    set = function(quality, value) StateManager:Dispatch(mergeAction({ qualities = { [quality] = value } })) end
  }))
end

--- Adds a line of a chip per equipment type to `box`, for a setting's selected
--- subclasses in `field`.
--- @param box OptionsBuilderSettingsBox
--- @param labelText string
--- @param equipmentTypes EquipmentType[]
--- @param field "armor" | "weapons"
--- @param columns integer
--- @param getState fun(): EquipmentTypeOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addEquipmentTypesLine(box, labelText, equipmentTypes, field, columns, getState, mergeAction)
  local chips = {}

  for _, equipmentType in ipairs(equipmentTypes) do
    local subclassId = equipmentType.subclassId
    chips[#chips + 1] = {
      text = equipmentType.name,
      get = function() return getState()[field][subclassId] == true end,
      set = function(value) StateManager:Dispatch(mergeAction({ [field] = { [subclassId] = value } })) end
    }
  end

  box:AddLine(labelText):AttachComponent(ComponentFactory:CheckChipGroup({ chips = chips, columns = columns }))
end

--- Adds an armor types line to the box for a setting's `armor` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): EquipmentTypeOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addArmorLine(self, getState, mergeAction)
  addEquipmentTypesLine(self, L.ARMOR, EquipmentTypes:GetArmorTypes(), "armor", 5, getState, mergeAction)
end

--- Adds a weapon types line to the box for a setting's `weapons` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): EquipmentTypeOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addWeaponsLine(self, getState, mergeAction)
  addEquipmentTypesLine(self, L.WEAPONS, EquipmentTypes:GetWeaponTypes(), "weapons", 3, getState, mergeAction)
end

--- Adds a divider and a settings box to the card, below its description. The
--- box is disabled and dimmed while the card is unchecked.
--- @param self OptionsBuilderCard
--- @return OptionsBuilderSettingsBox box
local function addSettingsBox(self)
  local divider = self.Content:AttachComponent(ComponentFactory:Divider())
  divider:SetMarginTop(Widgets:Padding(0.25))

  --- @class OptionsBuilderSettingsBox : SettingsBoxComponent
  local box = self.Content:AttachComponent(ComponentFactory:SettingsBox({
    isEnabled = function() return self:IsChecked() end
  }))
  box:SetMarginTop(Widgets:Padding(0.25))

  box.AddAppliesToLine = addAppliesToLine
  box.AddArmorLine = addArmorLine
  box.AddChoiceLine = addChoiceLine
  box.AddItemLevelLine = addItemLevelLine
  box.AddPriceLine = addPriceLine
  box.AddQualitiesLine = addQualitiesLine
  box.AddWeaponsLine = addWeaponsLine

  return box
end

-- ============================================================================
-- OptionsBuilder
-- ============================================================================

--- Creates a titled, scrollable options panel.
--- @param options OptionsBuilderPanelOptions
--- @return TitledPanelComponent panel
--- @return WaffleFlexComponent content Component the panel's rows are added to.
function OptionsBuilder:CreatePanel(options)
  local panel = ComponentFactory:TitledPanel(options)
  local scrollPanel = panel.Content:AttachComponent(ComponentFactory:ScrollPanel())
  local content = scrollPanel.ScrollChild
  content:SetGap(Widgets:Padding())

  if options.descriptionText then
    content:AttachComponent(ComponentFactory:Text({
      text = options.descriptionText,
      fontObject = "GameFontNormalSmall",
      color = Colors.Grey,
      justifyH = "CENTER"
    }))
    content:AttachComponent(ComponentFactory:Divider())
  end

  return panel, content
end

--- Adds an option card with a label and description to `container`.
--- @param container WaffleFlexComponent
--- @param options OptionsBuilderCardOptions
--- @return OptionsBuilderCard card
function OptionsBuilder:AddOptionCard(container, options)
  --- @class OptionsBuilderCard : OptionCardComponent
  local card = container:AttachComponent(ComponentFactory:OptionCard(options))

  card.Content:AttachComponent(ComponentFactory:Text({
    text = options.ignoresSpecialEquipment and (options.labelText .. Colors.Pink("*")) or options.labelText
  }))

  card.Content:AttachComponent(ComponentFactory:Text({
    text = options.descriptionText,
    fontObject = "GameFontNormalSmall",
    color = Colors.Grey
  }))

  if options.warningText then
    card.Content:AttachComponent(ComponentFactory:Text({
      text = options.warningText,
      fontObject = "GameFontNormalSmall",
      color = Colors.Pink
    }))
  end

  card.AddSettingsBox = addSettingsBox

  return card
end

--- Adds a group of options to `container` under a heading, after a divider
--- unless it is the first group.
--- @param container WaffleFlexComponent
--- @param headingText string
--- @return OptionsBuilderGroup group
function OptionsBuilder:AddGroup(container, headingText)
  if groupedContainers[container] then
    local divider = container:AttachComponent(ComponentFactory:Divider())
    divider:SetMarginTop(Widgets:Padding())
    divider:SetMarginBottom(Widgets:Padding())
  end
  groupedContainers[container] = true

  --- @class OptionsBuilderGroup : WaffleFlexComponent
  local group = container:AttachComponent(Addon.Waffle:Flex({
    direction = "COLUMN",
    height = "AUTO",
    gap = Widgets:Padding()
  }))

  group:AttachComponent(ComponentFactory:Text({ text = headingText, fontObject = "GameFontNormalLarge" }))

  --- Adds an option card to the group.
  --- @param options OptionsBuilderCardOptions
  --- @return OptionsBuilderCard card
  function group:AddOptionCard(options)
    return OptionsBuilder:AddOptionCard(self, options)
  end

  return group
end

--- Adds a centered footnote below `panel`'s scroll panel, under a divider,
--- explaining that options marked with an asterisk ignore special equipment.
--- @param panel TitledPanelComponent
function OptionsBuilder:AddSpecialEquipmentFootnote(panel)
  local divider = panel.Content:AttachComponent(ComponentFactory:Divider())
  divider:SetMarginTop(Widgets:Padding())

  local footnote = panel.Content:AttachComponent(ComponentFactory:Text({
    text = Colors.Pink("*") .. " " .. L.DOES_NOT_APPLY_TO_SPECIAL_EQUIPMENT,
    fontObject = "GameFontNormalSmall",
    color = Colors.Grey
  }))
  footnote:SetMarginTop(Widgets:Padding())
  footnote:SetMarginBottom(Widgets:Padding(0.5))
end
