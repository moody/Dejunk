local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ToggleOptionCardOptions : OptionCardBaseOptions
--- @field get fun(): boolean Returns `true` if the option is on.
--- @field set fun(value: boolean) Called with the new value when the card is clicked.

-- =============================================================================
-- ComponentFactory - ToggleOptionCard
-- =============================================================================

--- Creates an `OptionCard` with a checkbox beside its content. Clicking anywhere on the card toggles the option.
--- @param options ToggleOptionCardOptions
--- @return ToggleOptionCardComponent root
function ComponentFactory:ToggleOptionCard(options)
  local checkbox = Addon.Waffle:Flex({
    width = ComponentFactory.OPTION_CARD_LEADING_SIZE,
    height = ComponentFactory.OPTION_CARD_LEADING_SIZE,

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Checkbox({ parent = parent })
    end
  })

  --- @class ToggleOptionCardComponent : OptionCardComponent
  local root = ComponentFactory:OptionCard({
    leading = checkbox,
    onLeftClick = function() options.set(not options.get()) end,
    onRightClick = options.onRightClick,
    onUpdateTooltip = options.onUpdateTooltip
  })

  checkbox:WhenFrameReady(function(checkboxFrame) -- Refresh on hover, show, and state changes.
    --- @cast checkboxFrame CheckboxWidget
    --- @type FrameWidget
    local frame = root:GetFrame()

    --- Updates the checkbox.
    local function refresh()
      checkboxFrame:SetChecked(options.get())
      checkboxFrame:FireEvent("HOVERED", frame:GetEventValue("HOVERED"))
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

  --- Returns `true` if the option is on.
  --- @return boolean
  function root:IsChecked()
    return options.get()
  end

  return root
end
