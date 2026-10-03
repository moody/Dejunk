local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class TitledPanelComponentOptions
--- @field titleText string
--- @field titleJustify? "LEFT" | "CENTER" | "RIGHT" Defaults to `CENTER`.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shown while hovering the title bar.

-- =============================================================================
-- ComponentFactory - TitledPanel
-- =============================================================================

--- Creates a bordered panel with a title bar.
--- @param options TitledPanelComponentOptions
--- @return TitledPanelComponent root
function ComponentFactory:TitledPanel(options)
  --- @class TitledPanelComponent : WaffleFlexComponent
  --- @field TitleBar WaffleFlexComponent
  --- @field Content WaffleFlexComponent Fills the panel below the title bar, inset by `Widgets:Padding()`.
  local root = Addon.Waffle:Flex({
    direction = "COLUMN",

    defaultFrameFactory = function(parent)
      return Widgets:Frame({ parent = parent, backdrop = false, clipChildren = false })
    end,

    frameFactory = function(parent)
      return Widgets:Frame({ parent = parent })
    end
  })

  root.TitleBar = root:AddRow({
    height = "AUTO",
    padding = Widgets:Padding(),
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
      return frame
    end
  })

  root.TitleBar:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH(options.titleJustify or "CENTER")
      fontString:SetWordWrap(false)
      fontString:SetText(options.titleText)
      return fontString
    end,

    --- @param fontString FontString
    --- @param width number
    onMeasure = function(fontString, width)
      return width, fontString:GetStringHeight()
    end
  })

  root.Content = root:AddColumn({ padding = Widgets:Padding() })

  return root
end
