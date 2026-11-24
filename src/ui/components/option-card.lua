local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionCardOptions
--- @field get? fun(): boolean Returns `true` if the option is on. Without `get` and `set` the card is plain: it has no checkbox.
--- @field set? fun(value: boolean) Called with the new value when the card is clicked.
--- @field onLeftClick? fun() Called when a plain card is left-clicked. A card with `get` and `set` toggles instead.
--- @field onRightClick? fun() Called when the card is right-clicked.
--- @field onUpdateTooltip? fun(self: FrameWidget, tooltip: Tooltip) Shown while hovering the card.

-- =============================================================================
-- ComponentFactory - OptionCard
-- =============================================================================

--- Creates a full-width card with a checkbox beside its content. Clicking
--- anywhere on the card toggles the option. A plain card has no checkbox.
--- @param options OptionCardOptions
--- @return OptionCardComponent root
function ComponentFactory:OptionCard(options)
  --- @class OptionCardComponent : WaffleFlexComponent
  --- @field Content WaffleFlexComponent Column beside the checkbox.
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    align = "START",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        enableClickHandling = true,
        onUpdateTooltip = options.onUpdateTooltip
      })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.03))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      if options.get and options.set then
        frame:SetClickHandler("LeftButton", "NONE", function() options.set(not options.get()) end)
      elseif options.onLeftClick then
        frame:SetClickHandler("LeftButton", "NONE", options.onLeftClick)
      end
      if options.onRightClick then frame:SetClickHandler("RightButton", "NONE", options.onRightClick) end
      return frame
    end
  })

  -- Checkbox.
  if options.get then
    root:AddChild({
      width = 18,
      height = 18,

      --- @param parent Frame
      frameFactory = function(parent)
        return Widgets:Checkbox({ parent = parent })
      end
    }):WhenFrameReady(function(checkbox) -- Refresh on hover, show, and state changes.
      --- @cast checkbox CheckboxWidget
      --- @type FrameWidget
      local frame = root:GetFrame()

      --- Applies the hover fill to the card, and updates the checkbox.
      local function refresh()
        local isHovered = frame:GetEventValue("HOVERED")
        frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.06 or 0.03))
        checkbox:SetChecked(options.get())
        checkbox:FireEvent("HOVERED", isHovered)
      end

      -- The checked state reads the store.
      EventManager:WaitForFirst(E.StoreCreated, function()
        frame:OnEvent("HOVERED", refresh)
        frame:HookScript("OnShow", refresh)
        EventManager:On(E.StateUpdated, function()
          if frame:IsVisible() then refresh() end
        end)
      end)
    end)
  end

  root.Content = root:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })

  --- Returns `true` if the option is on. A plain card is always on.
  --- @return boolean
  function root:IsChecked()
    return options.get == nil or options.get()
  end

  return root
end
