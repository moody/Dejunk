local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")

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

--- @class OptionButtonItemQualityCheckBoxesOptions
--- @field poor CheckBoxWidgetOptions
--- @field common CheckBoxWidgetOptions
--- @field uncommon CheckBoxWidgetOptions
--- @field rare CheckBoxWidgetOptions
--- @field epic CheckBoxWidgetOptions

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
  frame.itemQualityCheckBoxes = {}

  -- Check box.
  frame.checkBox = self:CheckBox({
    parent = frame,
    name = "$parent_CheckBox",
    points = { { "TOPRIGHT", -Widgets:Padding(), -Widgets:Padding() } },
    color = Colors.White,
    get = options.get,
    set = options.set
  })
  frame.checkBox:EnableMouse(false)

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("TOPLEFT", frame, Widgets:Padding(), -Widgets:Padding())
  frame.label:SetPoint("RIGHT", frame.checkBox, "LEFT", -Widgets:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame.label:SetJustifyH("LEFT")

  local CHECK_BOX_SIZE = math.floor(frame.label:GetStringHeight())
  local ITEM_QUALITY_CHECK_BOX_SIZE = math.floor(CHECK_BOX_SIZE * 1.5)
  frame.checkBox:SetSize(CHECK_BOX_SIZE, CHECK_BOX_SIZE)

  --- @param options OptionButtonItemQualityCheckBoxesOptions
  function frame:InitializeItemQualityCheckBoxes(options)
    -- Set additional options.
    for k, v in pairs(options) do
      v.parent = frame
      v.name = "$parent_ItemQualityButton_" .. k
      v.width = ITEM_QUALITY_CHECK_BOX_SIZE
      v.height = ITEM_QUALITY_CHECK_BOX_SIZE

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
        tooltip:AddLine(L.ITEM_QUALITY_CHECK_BOX_TOOLTIP)
      end
    end

    -- Add check boxes.
    table.insert(frame.itemQualityCheckBoxes, Widgets:CheckBox(options.poor))
    table.insert(frame.itemQualityCheckBoxes, Widgets:CheckBox(options.common))
    table.insert(frame.itemQualityCheckBoxes, Widgets:CheckBox(options.uncommon))
    table.insert(frame.itemQualityCheckBoxes, Widgets:CheckBox(options.rare))
    table.insert(frame.itemQualityCheckBoxes, Widgets:CheckBox(options.epic))

    -- Position check boxes.
    for i, cb in ipairs(frame.itemQualityCheckBoxes) do
      if i == 1 then
        cb:SetPoint("TOPLEFT", frame.label, "BOTTOMLEFT", 0, -Widgets:Padding())
      else
        cb:SetPoint("LEFT", frame.itemQualityCheckBoxes[i - 1], "RIGHT", Widgets:Padding(), 0)
      end
    end
  end

  frame:HookScript("OnEnter", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
  end)

  frame:HookScript("OnLeave", function()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
  end)

  frame:SetScript("OnClick", function()
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function()
    frame:SetAlpha(options.get() and 1 or 0.5)

    -- Set frame height.
    if #frame.itemQualityCheckBoxes > 0 then
      frame:SetHeight(CHECK_BOX_SIZE + Widgets:Padding() + ITEM_QUALITY_CHECK_BOX_SIZE + Widgets:Padding(2))
    else
      frame:SetHeight(CHECK_BOX_SIZE + Widgets:Padding(2))
    end
  end)

  do -- Hack to fix a bug where check boxes are sometimes invisible.
    local function showCheckBoxes()
      frame.checkBox:Show()
      for _, cb in pairs(frame.itemQualityCheckBoxes) do
        cb:Show()
      end
    end

    -- OnShow: hide all check boxes, then show them again after 0.01 seconds.
    frame:SetScript("OnShow", function()
      frame.checkBox:Hide()
      for _, cb in pairs(frame.itemQualityCheckBoxes) do
        cb:Hide()
      end
      C_Timer.After(0.01, showCheckBoxes)
    end)
  end

  return frame
end
