local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class OptionsBuilder
local OptionsBuilder = Addon:GetModule("OptionsBuilder")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class OptionsBuilderTextOptions
--- @field labelText string Option name.
--- @field descriptionText string Shown in grey below the label.
--- @field warningText? string Shown in pink below the description.
--- @field ignoresSpecialEquipment? boolean Marks the label with an asterisk explained by `AddSpecialEquipmentFootnote()`.

--- @class OptionsBuilderCardOptions : OptionCardOptions, OptionsBuilderTextOptions

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Adds an editable item level line to the box for a setting's `value` field.
--- @param self OptionsBuilderSettingsBox
--- @param getState fun(): ItemLevelOptionState
--- @param mergeAction fun(t: table): WuxPayloadAction
local function addItemLevelLine(self, getState, mergeAction)
  self:AddLine(L.ITEM_LEVEL):AttachComponent(ComponentFactory:NumberInput({
    get = function() return getState().value end,
    set = function(value) StateManager:Dispatch(mergeAction({ value = value })) end
  }))
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

--- Adds a divider and a settings box to the card, below its description. The
--- box dims while the card is unchecked.
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

  box.AddItemLevelLine = addItemLevelLine
  box.AddQualitiesLine = addQualitiesLine

  return box
end

-- ============================================================================
-- OptionsBuilder
-- ============================================================================

--- Creates a titled, scrollable options panel.
--- @param options TitledPanelComponentOptions
--- @return TitledPanelComponent panel
--- @return WaffleFlexComponent content Component the panel's rows are added to.
function OptionsBuilder:CreatePanel(options)
  local panel = ComponentFactory:TitledPanel(options)
  local scrollPanel = panel.Content:AttachComponent(ComponentFactory:ScrollPanel())
  scrollPanel.ScrollChild:SetGap(Widgets:Padding())
  return panel, scrollPanel.ScrollChild
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
