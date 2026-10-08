local Addon = select(2, ...) ---@type Addon
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Most pixels scrolled by one wheel notch.
local WHEEL_STEP = 48

--- Returns where scrolling ends up after one wheel notch, from `0` to `max`.
--- @param position number Where scrolling is.
--- @param delta number Positive scrolls up, negative scrolls down.
--- @param step number Pixels per notch.
--- @param max number
--- @return integer
local function getWheelTarget(position, delta, step, max)
  local target = math.floor(position - step * delta + 0.5)
  return math.max(0, math.min(target, max))
end

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

  local scrollFrame = Widgets:Frame({ frameType = "ScrollFrame", backdrop = false })
  local scrollChild = Widgets:Frame({ parent = scrollFrame, backdrop = false, clipChildren = false })
  scrollFrame:SetScrollChild(scrollChild)
  scrollFrame:Hide()

  local slider = Widgets:Slider({ orientation = "VERTICAL" })
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
    return Widgets:Frame({ parent = parent, backdrop = false, clipChildren = false })
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
        local _, max = slider:GetMinMaxValues()
        -- An eighth of the range, from a third of WHEEL_STEP up to WHEEL_STEP.
        local step = Clamp(max / 8, WHEEL_STEP / 3, WHEEL_STEP)
        slider:SetValue(getWheelTarget(slider:GetValue(), delta, step, max))
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
      Components.Root.ScrollChild:Layout()
      updateSlider()
    end
  })

  Components.SliderColumn = Components.ScrollRow:AddColumn({
    frame = slider,
    width = 12,
    visibility = "GONE"
  })

  -- The thumb is invisible on the first layout, so we
  -- re-show the slider a frame later to fix it.
  Components.SliderColumn:SetOnLayout(function()
    Components.SliderColumn:SetOnLayout(nil)
    TickerManager:After(0, function()
      if not slider:IsShown() then return end
      slider:Hide()
      slider:Show()
    end)
  end)

  return Components.Root
end
