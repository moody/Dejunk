local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Tooltip = Addon:GetModule("Tooltip")

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
--- @field minHeight? integer Height the text is placed in, by `justifyV`, when it is shorter.

-- =============================================================================
-- ComponentFactory - Text
-- =============================================================================

--- Creates a block of text. Shows a tooltip on hover if truncated.
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

      fontString:SetPropagateMouseClicks(true)
      fontString:SetPropagateMouseMotion(true)
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

      return fontString
    end,

    --- @param fontString FontString
    --- @param width? number
    onMeasure = function(fontString, width)
      if not width then
        fontString:SetTextToFit(fontString:GetText())
        return fontString:GetStringWidth(), math.max(fontString:GetStringHeight(), options.minHeight or 0)
      end

      fontString:SetSize(width, 0)
      return width, math.max(fontString:GetStringHeight(), options.minHeight or 0)
    end
  })
end
