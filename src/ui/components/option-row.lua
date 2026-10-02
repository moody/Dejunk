local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionRowOptions
--- @field labelText string
--- @field descriptionText string
--- @field get fun(): boolean
--- @field set fun(value: boolean)
--- @field onRightClick? fun()
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip)

-- =============================================================================
-- ComponentFactory - OptionRow
-- =============================================================================

--- Creates a full-width row with a checkbox, label, and description. Clicking
--- anywhere on the row toggles the option.
--- @param options OptionRowOptions
--- @return WaffleFlexComponent root
function ComponentFactory:OptionRow(options)
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    align = "START",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        enableClickHandling = true,
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.1)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
      frame:SetClickHandler("LeftButton", "NONE", function() options.set(not options.get()) end)
      if options.onRightClick then frame:SetClickHandler("RightButton", "NONE", options.onRightClick) end
      return frame
    end
  })

  root:AddChild({
    width = 16,
    height = 16,

    --- @param parent Frame
    frameFactory = function(parent)
      local checkBox = Widgets:CheckBox({ parent = parent, get = options.get, set = options.set })
      checkBox:EnableMouse(false)
      return checkBox
    end
  })

  -- Label and description.
  local text = root:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })

  --- Adds a wrapping text line.
  --- @param fontObject string
  --- @param color Color
  --- @param value string
  local function addTextLine(fontObject, color, value)
    text:AddChild({
      height = "AUTO",

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", fontObject)
        fontString:SetJustifyH("LEFT")
        fontString:SetWordWrap(true)
        fontString:SetTextColor(color:GetRGB())
        fontString:SetText(value)
        return fontString
      end,

      --- @param fontString FontString
      --- @param width number
      onMeasure = function(fontString, width)
        fontString:SetSize(width, 0)
        return width, fontString:GetStringHeight()
      end
    })
  end

  addTextLine("GameFontNormal", Colors.White, options.labelText)
  addTextLine("GameFontNormalSmall", Colors.Grey, options.descriptionText)

  return root
end
