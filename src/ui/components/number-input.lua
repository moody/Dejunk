local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class NumberInputComponentOptions
--- @field get fun(): integer Returns the value to show. Re-read whenever the state changes.
--- @field set fun(value: integer) Called with the entered value shortly after typing stops, or on Enter or losing focus.
--- @field width? integer Defaults to `80`.
--- @field maxLetters? integer Defaults to `5`.

-- =============================================================================
-- ComponentFactory - NumberInput
-- =============================================================================

--- Creates an edit box for a whole number. Escape, or leaving it empty,
--- restores the current value.
--- @param options NumberInputComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:NumberInput(options)
  return Addon.Waffle:Flex({
    width = options.width or 80,
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class NumberInputWidget : FrameWidget, EditBox
      local editBox = Widgets:Frame({ parent = parent, frameType = "EditBox" })
      editBox:SetBackdropColor(Colors.Black:GetRGBA(0.4))
      editBox:SetFontObject(Widgets.CONTROL_FONT)
      editBox:SetTextColor(Colors.White:GetRGB())
      editBox:SetJustifyH("CENTER")
      editBox:SetTextInsets(Widgets:Padding(0.5), Widgets:Padding(0.5), 0, 0)
      editBox:SetAutoFocus(false)
      editBox:SetNumeric(true)
      editBox:SetMaxLetters(options.maxLetters or 5)

      --- Saves the entered value, ignoring an empty box.
      local function save()
        local value = tonumber(editBox:GetText())
        if value and value ~= options.get() then options.set(value) end
      end

      -- Debounce a save on user input.
      local debounceSave = TickerManager:NewDebouncer(0.5, save)
      editBox:SetScript("OnTextChanged", function(_, isUserInput)
        if isUserInput then debounceSave() end
      end)

      editBox:SetScript("OnEnterPressed", editBox.ClearFocus)
      editBox:SetScript("OnHide", editBox.ClearFocus)
      editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(options.get()))
        self:ClearFocus()
      end)

      --- Shows the current value, unless the box has focus.
      local function refreshText()
        if editBox:HasFocus() then return end
        editBox:SetText(tostring(options.get()))
      end

      --- Brightens the border while hovered or focused. Hover is ignored while disabled.
      local function refreshBorder()
        local isHovered = editBox:GetEventValue("HOVERED") and editBox:GetEventValue("ENABLED")
        local alpha = (editBox:GetEventValue("FOCUSED") and 0.5) or (isHovered and 0.4) or 0.15
        editBox:SetBackdropBorderColor(Colors.White:GetRGBA(alpha))
      end

      -- Set up event handlers.
      editBox:OnEvent("FOCUSED", function(isFocused)
        if isFocused then
          editBox:HighlightText()
        else
          editBox:HighlightText(0, 0)
          save()
          refreshText()
        end
        refreshBorder()
      end)
      editBox:OnEvent("HOVERED", refreshBorder)
      editBox:OnEvent("ENABLED", refreshBorder)
      EventManager:On(E.StateUpdated, refreshText)

      return editBox
    end,

    --- @param editBox NumberInputWidget
    --- @param width number
    onMeasure = function(editBox, width)
      local _, fontHeight = editBox:GetFont()
      return width, fontHeight + Widgets.CONTROL_PADDING * 2
    end
  })
end
