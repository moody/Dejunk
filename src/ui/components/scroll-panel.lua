local Addon = select(2, ...) ---@type Addon
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- ComponentFactory - ScrollPanel
-- =============================================================================

--- Creates a vertically scrollable Waffle region. Its slider only shows when
--- the content actually overflows the viewport.
--- @return ScrollPanelComponent root
function ComponentFactory:ScrollPanel()
  local Components = {}

  ------------------------------------------------------------
  -- Frames
  ------------------------------------------------------------

  local scrollFrame = CreateFrame("ScrollFrame")
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollFrame:SetScrollChild(scrollChild)
  scrollFrame:Hide()

  local slider = Widgets:Slider({ orientation = "VERTICAL" })
  slider:SetAllPoints()
  slider:SetScript("OnValueChanged", function(_, value)
    local min, max = slider:GetMinMaxValues()
    scrollFrame:SetVerticalScroll(Clamp(math.floor(value + 0.5), min, max))
  end)
  slider:Hide()

  ------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------

  --- Recomputes the slider's range and shows or hides it as necessary.
  local function updateSlider()
    local maxScroll = math.max(scrollChild:GetHeight() - scrollFrame:GetHeight(), 0)
    slider:SetMinMaxValues(0, maxScroll)
    Components.SliderColumn:SetVisibility(maxScroll > 0 and "VISIBLE" or "GONE")
  end

  --- Creates a plain frame for children with no frameFactory of their own.
  local function defaultFrameFactory(parent)
    return CreateFrame("Frame", nil, parent)
  end

  ------------------------------------------------------------
  -- Root
  ------------------------------------------------------------

  --- @class ScrollPanelComponent : WaffleFlexComponent
  --- @field ScrollChild WaffleFlexComponent Root for scrollable content.
  Components.Root = Addon.Waffle:Flex({
    direction = "COLUMN",
    defaultFrameFactory = defaultFrameFactory,

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        local min, max = slider:GetMinMaxValues()
        slider:SetValue(Clamp(slider:GetValue() - scrollFrame:GetHeight() * 0.75 * delta, min, max))
      end)
      return frame
    end,
  })

  ------------------------------------------------------------
  -- ScrollChild
  ------------------------------------------------------------

  -- This component for `scrollChild` must be its own root since `scrollFrame`
  -- will handle the actual positioning of the frame instead of Waffle.
  Components.Root.ScrollChild = Addon.Waffle:Flex({
    frame = scrollChild,
    direction = "COLUMN",
    height = "AUTO",
    onLayout = updateSlider,
    defaultFrameFactory = defaultFrameFactory,
  })

  TickerManager:NewTicker(1 / 30, function()
    Components.Root.ScrollChild:Layout()
  end):BindFrame(scrollChild)

  ------------------------------------------------------------
  -- ScrollRow
  ------------------------------------------------------------

  -- Holds ScrollFrame and SliderColumn side by side.
  Components.ScrollRow = Components.Root:AddRow({ gap = Widgets:Padding(0.5) })

  -- Wraps the native ScrollFrame.
  Components.ScrollFrame = Components.ScrollRow:AddRow({
    frame = scrollFrame,
    onLayout = function(_, width)
      Components.Root.ScrollChild:SetWidth(width)
      updateSlider()
    end
  })

  Components.SliderColumn = Components.ScrollRow:AddColumn({
    frame = slider,
    width = 12,
    visibility = "GONE"
  })

  return Components.Root
end
