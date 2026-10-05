local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionButtonWidgetOptions : FrameWidgetOptions
--- @field labelText string
--- @field tooltipText? string
--- @field get fun(): boolean
--- @field set fun(value: boolean)

--- @class OptionButtonItemQualityCheckboxesOptions
--- @field poor CheckboxWidgetOptions
--- @field common CheckboxWidgetOptions
--- @field uncommon CheckboxWidgetOptions
--- @field rare CheckboxWidgetOptions
--- @field epic CheckboxWidgetOptions

-- =============================================================================
-- Widgets - Option Button
-- =============================================================================

--- Creates a toggleable option button.
--- @param options OptionButtonWidgetOptions
--- @return OptionButtonWidget frame
function Widgets:OptionButton(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("OptionButton"))
  options.frameType = "Button"

  if options.tooltipText then
    options.onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(options.labelText)
      tooltip:AddLine(options.tooltipText)
    end
  end

  --- @class OptionButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
  frame.itemQualityCheckboxes = {}

  -- Checkbox.
  frame.checkbox = self:Checkbox({
    parent = frame,
    name = "$parent_Checkbox",
    points = { { "TOPRIGHT", -Widgets:Padding(), -Widgets:Padding() } },
    color = Colors.White
  })

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("TOPLEFT", frame, Widgets:Padding(), -Widgets:Padding())
  frame.label:SetPoint("RIGHT", frame.checkbox, "LEFT", -Widgets:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame.label:SetJustifyH("LEFT")

  local CHECKBOX_SIZE = math.floor(frame.label:GetStringHeight())
  local ITEM_QUALITY_CHECKBOX_SIZE = math.floor(CHECKBOX_SIZE * 1.5)
  frame.checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
  frame:SetHeight(CHECKBOX_SIZE + Widgets:Padding(2))

  --- @param options OptionButtonItemQualityCheckboxesOptions
  function frame:InitializeItemQualityCheckboxes(options)
    -- Set additional options.
    for k, v in pairs(options) do
      v.parent = frame
      v.name = "$parent_ItemQualityButton_" .. k
      v.width = ITEM_QUALITY_CHECKBOX_SIZE
      v.height = ITEM_QUALITY_CHECKBOX_SIZE

      local text

      if k == "poor" then
        text = L.POOR
        v.color = Colors.QualityPoor
      elseif k == "common" then
        text = L.COMMON
        v.color = Colors.QualityCommon
      elseif k == "uncommon" then
        text = L.UNCOMMON
        v.color = Colors.QualityUncommon
      elseif k == "rare" then
        text = L.RARE
        v.color = Colors.QualityRare
      elseif k == "epic" then
        text = L.EPIC
        v.color = Colors.QualityEpic
      end

      v.onUpdateTooltip = function(_, tooltip)
        tooltip:SetText(v.color(text))
        tooltip:AddLine(L.ITEM_QUALITY_CHECKBOX_TOOLTIP)
      end
    end

    -- Add checkboxes.
    table.insert(frame.itemQualityCheckboxes, Widgets:Checkbox(options.poor))
    table.insert(frame.itemQualityCheckboxes, Widgets:Checkbox(options.common))
    table.insert(frame.itemQualityCheckboxes, Widgets:Checkbox(options.uncommon))
    table.insert(frame.itemQualityCheckboxes, Widgets:Checkbox(options.rare))
    table.insert(frame.itemQualityCheckboxes, Widgets:Checkbox(options.epic))

    -- Position checkboxes.
    for i, cb in ipairs(frame.itemQualityCheckboxes) do
      if i == 1 then
        cb:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -Widgets:Padding())
      else
        cb:SetPoint("LEFT", frame.itemQualityCheckboxes[i - 1], "RIGHT", Widgets:Padding(), 0)
      end
    end

    frame:SetHeight(CHECKBOX_SIZE + Widgets:Padding() + ITEM_QUALITY_CHECKBOX_SIZE + Widgets:Padding(2))
  end

  frame:HookScript("OnEnter", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
    frame.checkbox:FireEvent("HOVERED", true)
  end)

  frame:HookScript("OnLeave", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    frame.checkbox:FireEvent("HOVERED", false)
  end)

  frame:SetScript("OnClick", function()
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function()
    frame:SetAlpha(options.get() and 1 or 0.5)
  end)

  -- Keep the checkbox in step with the option.
  TickerManager:NewTicker(1 / 30, function()
    frame.checkbox:SetChecked(options.get())
  end):BindFrame(frame)

  do -- Hack to fix a bug where checkboxes are sometimes invisible.
    local function showCheckboxes()
      frame.checkbox:Show()
      for _, cb in pairs(frame.itemQualityCheckboxes) do
        cb:Show()
      end
    end

    -- OnShow: hide all checkboxes, then show them again after 0.01 seconds.
    frame:SetScript("OnShow", function()
      frame.checkbox:Hide()
      for _, cb in pairs(frame.itemQualityCheckboxes) do
        cb:Hide()
      end
      C_Timer.After(0.01, showCheckboxes)
    end)
  end

  return frame
end
