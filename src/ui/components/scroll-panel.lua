local Addon = select(2, ...) ---@type Addon
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Pixels scrolled by one wheel notch, at most half the viewport.
local WHEEL_STEP = 48

--- How fast scrolling eases toward its target. Higher is faster.
local EASE_SPEED = 18

--- Returns where scrolling ends up after one wheel notch, from `0` to `max`.
--- @param position number Where scrolling is, or is heading to.
--- @param delta number Positive scrolls up, negative scrolls down.
--- @param step number Pixels per notch.
--- @param max number
--- @return integer
local function getWheelTarget(position, delta, step, max)
  local target = math.floor(position - step * delta + 0.5)
  return math.max(0, math.min(target, max))
end

--- Returns the next position on the way to `target`. It slows as it nears `target`, moves at least a pixel,
--- and never passes it.
--- @param position number
--- @param target number
--- @param elapsed number Seconds since the last step.
--- @return number
local function ease(position, target, elapsed)
  local distance = target - position
  local move = distance * (1 - math.exp(-EASE_SPEED * elapsed))

  -- At least a pixel, so it always arrives.
  if math.abs(move) < 1 then move = distance < 0 and -1 or 1 end
  if math.abs(move) >= math.abs(distance) then return target end

  return position + move
end

--- Stops moving the slider toward its `scrollTarget`.
--- @param slider ScrollPanelSliderWidget
local function stopScrolling(slider)
  slider.scrollTarget = nil
  slider:SetScript("OnUpdate", nil)
end

--- Moves the slider toward its `scrollTarget` each frame, then stops.
--- @param slider ScrollPanelSliderWidget
--- @param elapsed number
local function easeToTarget(slider, elapsed)
  local target = slider.scrollTarget
  if not target then
    stopScrolling(slider)
    return
  end

  local position = ease(slider:GetValue(), target, elapsed)
  slider:SetValue(position)

  if position == target then
    stopScrolling(slider)
  end
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

  --- @class ScrollPanelSliderWidget : SliderWidget
  local slider = Widgets:Slider({ orientation = "VERTICAL" })
  slider:SetScript("OnValueChanged", function(_, value)
    local min, max = slider:GetMinMaxValues()
    scrollFrame:SetVerticalScroll(Clamp(math.floor(value + 0.5), min, max))
  end)
  slider:Hide()

  --- Where the wheel is scrolling to, or `nil` when it is not scrolling.
  --- @type number?
  slider.scrollTarget = nil

  -- Dragging the thumb or hiding the slider stops the wheel.
  slider:HookScript("OnMouseDown", stopScrolling)
  slider:HookScript("OnHide", stopScrolling)

  ------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------

  --- Recomputes the slider's range and shows or hides it as necessary.
  local function updateSlider()
    local maxScroll = math.max(scrollChild:GetHeight() - scrollFrame:GetHeight(), 0)
    slider:SetMinMaxValues(0, maxScroll)
    if slider.scrollTarget then slider.scrollTarget = math.min(slider.scrollTarget, maxScroll) end
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
        local step = math.min(WHEEL_STEP, scrollFrame:GetHeight() / 2)
        slider.scrollTarget = getWheelTarget(slider.scrollTarget or slider:GetValue(), delta, step, max)
        slider:SetScript("OnUpdate", easeToTarget)
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
