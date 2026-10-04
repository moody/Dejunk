local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TextInputComponentOptions
--- @field placeholderText? string Shown while the box is empty.
--- @field fontObject? string Defaults to `Widgets.CONTROL_FONT`.
--- @field onTextChanged? fun(text: string) Called when the text changes, including through `SetText()`.

-- =============================================================================
-- ComponentFactory - TextInput
-- =============================================================================

--- Creates a single-line text box. Escape and Enter leave it. Attached
--- components appear after the text, inside the border.
--- @param options? TextInputComponentOptions
--- @return TextInputComponent root
function ComponentFactory:TextInput(options)
  options = options or {}
  local fontObject = options.fontObject or Widgets.CONTROL_FONT
  local _, fontHeight = _G[fontObject]:GetFont()

  --- @class TextInputComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = fontHeight + Widgets:Padding(2),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.Black:GetRGBA(0.4))
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.15))
      return frame
    end
  })

  --- The edit box.
  root.Input = root:AddChild({
    --- @param parent FrameWidget
    frameFactory = function(parent)
      --- @class TextInputWidget : FrameWidget, EditBox
      local editBox = Widgets:Frame({
        parent = parent,
        frameType = "EditBox",
        backdrop = false,
        clipChildren = false
      })
      editBox:SetFontObject(fontObject)
      editBox:SetTextColor(Colors.White:GetRGB())
      editBox:SetAutoFocus(false)
      editBox:SetMultiLine(false)
      editBox:SetCountInvisibleLetters(true)

      local leftInset, rightInset = Widgets:Padding(), Widgets:Padding(0.5)
      editBox:SetTextInsets(leftInset, rightInset, 0, 0)

      -- Placeholder.
      local placeholder = editBox:CreateFontString("$parent_Placeholder", "ARTWORK", fontObject)
      placeholder:SetText(options.placeholderText or "")
      placeholder:SetTextColor(Colors.Grey:GetRGB())
      placeholder:SetPoint("LEFT", leftInset, 0)
      placeholder:SetPoint("RIGHT", -rightInset, 0)
      placeholder:SetJustifyH("LEFT")

      local isHovered = false

      --- Colors the border blue while focused, and brightens it while hovered.
      local function refreshBorder()
        if editBox:HasFocus() then
          parent:SetBackdropBorderColor(Colors.Blue:GetRGBA(0.75))
        else
          parent:SetBackdropBorderColor(Colors.White:GetRGBA(isHovered and 0.4 or 0.15))
        end
      end

      editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
      editBox:SetScript("OnEnterPressed", editBox.ClearFocus)
      editBox:SetScript("OnEditFocusGained", refreshBorder)
      editBox:SetScript("OnEditFocusLost", refreshBorder)
      editBox:SetScript("OnEnter", function()
        isHovered = true
        refreshBorder()
      end)
      editBox:SetScript("OnLeave", function()
        isHovered = false
        refreshBorder()
      end)
      editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        placeholder:SetShown(text == "")
        if options.onTextChanged then options.onTextChanged(text) end
      end)

      return editBox
    end
  })

  --- Returns the current text, or an empty string before the frame exists.
  --- @return string
  function root:GetText()
    local editBox = self.Input:GetFrame()
    return editBox and editBox:GetText() or ""
  end

  --- Sets the text.
  --- @param text string
  function root:SetText(text)
    self.Input:WhenFrameReady(function(editBox)
      editBox:SetText(text)
    end)
  end

  return root
end
