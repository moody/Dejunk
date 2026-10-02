local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TextComponentOptions
--- @field text string Text to show.
--- @field fontObject? string Defaults to `GameFontNormal`.
--- @field color? Color Defaults to `Colors.White`.
--- @field justifyH? "LEFT" | "CENTER" | "RIGHT" Defaults to `LEFT`.
--- @field justifyV? "TOP" | "MIDDLE" | "BOTTOM" Defaults to `MIDDLE`.
--- @field wordWrap? boolean Defaults to `true`.
--- @field width? integer | "AUTO" `"AUTO"` fits the text on one line. Defaults to the available width.

-- =============================================================================
-- ComponentFactory - Text
-- =============================================================================

--- Creates a block of text.
--- @param options TextComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:Text(options)
  return Addon.Waffle:Flex({
    width = options.width,
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", options.fontObject or "GameFontNormal")
      fontString:SetJustifyH(options.justifyH or "LEFT")
      fontString:SetJustifyV(options.justifyV or "MIDDLE")
      fontString:SetWordWrap(Addon:IfNil(options.wordWrap, true))
      fontString:SetTextColor((options.color or Colors.White):GetRGB())
      fontString:SetText(options.text)
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
end
