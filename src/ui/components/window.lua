local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class WindowComponentOptions
--- @field name string Used for the frame's name.
--- @field width integer
--- @field height integer
--- @field titleText string
--- @field getPoint fun(): table Returns the point to apply.
--- @field setPoint fun(point: table) Called with the point to save after dragging.
--- @field onResetPoint fun() Called on Shift+Right-Click to reset the window's position.
--- @field refresh? fun() Called repeatedly while the window is visible.

--- @class WindowComponent : WaffleFlexComponent
--- @field TitleRow WaffleFlexComponent
--- @field TitleText WaffleFlexComponent
--- @field CloseButton WaffleFlexComponent

-- =============================================================================
-- ComponentFactory - Window
-- =============================================================================

--- Creates a draggable floating window with a title bar and close button.
--- Position is persisted and resettable with Shift+Right-Click.
--- @param options WindowComponentOptions
--- @return WindowComponent root
function ComponentFactory:Window(options)
  local root

  --- @class WindowComponent : WaffleFlexComponent
  root = Addon.Waffle:Flex({
    width = options.width,
    height = options.height,
    direction = "COLUMN",
    hidden = true,

    defaultFrameFactory = function(parent)
      return CreateFrame("Frame")
    end,

    frameFactory = function(parent)
      local frame = Widgets:Frame({
        name = ADDON_NAME .. "_" .. options.name,
        enableClickHandling = true,
        enableDragging = true
      })

      frame:SetClickHandler("RightButton", "SHIFT", options.onResetPoint)

      Widgets:ConfigureForPointSync({
        frame = frame,
        getPoint = options.getPoint,
        setPoint = options.setPoint
      })

      table.insert(UISpecialFrames, frame:GetName())

      frame:Hide()
      frame:HookScript("OnHide", function()
        root:SetHidden(true)
      end)

      -- Bind the refresh callback to the root frame, if given.
      if options.refresh then
        TickerManager:NewTicker(1 / 30, options.refresh):BindFrame(frame)
      end

      return frame
    end
  })

  root.TitleRow = root:AddRow({
    height = 32,
    paddingLeft = Widgets:Padding(),
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
      return frame
    end
  })

  root.TitleText = root.TitleRow:AddChild({
    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
      fontString:SetWordWrap(false)
      fontString:SetJustifyH("LEFT")
      fontString:SetText(options.titleText)
      return fontString
    end
  })

  root.CloseButton = root.TitleRow:AttachComponent(
    ComponentFactory:WindowTitleButton({
      name = "$parent_CloseButton",
      texture = Addon:GetAsset("x-icon"),
      textureSize = 14,
      highlightColor = Colors.Red,
      onClick = function()
        root:SetHidden(true)
        root:Layout()
      end
    })
  )

  return root
end
