local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Tooltip = Addon:GetModule("Tooltip")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TextComponentOptions
--- @field text? string Text to show. Defaults to an empty string.
--- @field fontObject? Font | string Font object or font name. Defaults to `B.FontObjects.Normal`.
--- @field color? Color Defaults to `Colors.White`.
--- @field justifyH? "LEFT" | "CENTER" | "RIGHT" Defaults to `LEFT`.
--- @field justifyV? "TOP" | "MIDDLE" | "BOTTOM" Defaults to `MIDDLE`.
--- @field wordWrap? boolean Defaults to `true`.
--- @field width? integer | "AUTO" `"AUTO"` fits the text on one line. Defaults to the available width.
--- @field truncationTooltip? boolean Whether hovering truncated text shows it in a tooltip. Defaults to `true`.

-- =============================================================================
-- ComponentFactory - Text
-- =============================================================================

--- Creates a block of text. Shows a tooltip on hover if truncated.
--- @param options TextComponentOptions
--- @return TextComponent root
function ComponentFactory:Text(options)
  --- @type FontString?
  local fontString
  local text = options.text or ""

  --- @class TextComponent : WaffleFlexComponent<FontString>
  local root = Addon.Waffle:Flex({
    width = options.width,
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontObject = options.fontObject or B.FontObjects.Normal
      local fontName = type(fontObject) == "string" and fontObject or fontObject:GetName()

      fontString = parent:CreateFontString(nil, "ARTWORK", fontName)
      fontString:SetJustifyH(options.justifyH or "LEFT")
      fontString:SetJustifyV(options.justifyV or "MIDDLE")
      fontString:SetWordWrap(Addon:IfNil(options.wordWrap, true))
      fontString:SetTextColor((options.color or Colors.White):GetRGB())
      fontString:SetText(text)

      fontString:SetPropagateMouseClicks(true)
      fontString:SetPropagateMouseMotion(true)
      if options.truncationTooltip ~= false then
        fontString:SetScript("OnEnter", function(self)
          if self:IsTruncated() then
            Tooltip:SetOwner(self, "ANCHOR_TOP")
            Tooltip:SetText(self:GetText())
            Tooltip:Show()
          end
        end)
        fontString:SetScript("OnLeave", function(self)
          if self:IsTruncated() then Tooltip:Hide() end
        end)
      end

      return fontString
    end,

    --- @param fontString FontString
    --- @param width? number
    onMeasure = function(fontString, width)
      if not width then
        fontString:SetTextToFit(fontString:GetText())
        return fontString:GetStringWidth(), fontString:GetStringHeight()
      end

      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end
  })

  --- Sets the text. Does nothing if it is unchanged.
  --- @param newText string
  function root:SetText(newText)
    if newText == text then return end

    text = newText
    if fontString then
      fontString:SetText(text)
      self:MarkDirty()
    end
  end

  return root
end
