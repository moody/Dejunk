local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class KeybindingCardOptions
--- @field labelText string Label of the binding.
--- @field descriptionText? string Shown in grey below the label.
--- @field get fun(): string? Returns the text of the bound key, or `nil` while there is none.
--- @field isListening fun(): boolean Returns whether the card's binding is waiting for a key.
--- @field onClick fun(mouseButton: string) Called when the button is clicked.

-- =============================================================================
-- ComponentFactory - KeybindingCard
-- =============================================================================

--- Creates a full-width card with a label and a button that shows the bound
--- key, or that there is none.
--- @param options KeybindingCardOptions
--- @return KeybindingCardComponent root
function ComponentFactory:KeybindingCard(options)
  --- @class KeybindingCardComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "COLUMN",
    height = "AUTO",
    gap = Widgets:Padding(0.5),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.03))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end
  })

  local row = root:AddRow({ height = "AUTO", align = "CENTER", gap = Widgets:Padding() })

  local text = row:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })
  text:AttachComponent(ComponentFactory:Text({ text = options.labelText }))

  if options.descriptionText then
    text:AttachComponent(ComponentFactory:Text({
      text = options.descriptionText,
      fontObject = "GameFontNormalSmall",
      color = Colors.Grey
    }))
  end

  row:AddChild({
    width = 140,
    height = 30,

    --- @param parent Frame
    frameFactory = function(parent)
      local button = Widgets:Button({
        parent = parent,
        labelText = L.NOT_BOUND,
        labelColor = Colors.Grey,
        onClick = function(_, mouseButton) options.onClick(mouseButton) end,
        tooltipAnchor = "ANCHOR_RIGHT",

        --- Shows the binding and its key, or nothing while there is no key.
        onUpdateTooltip = function(_, tooltip)
          local key = options.get()
          if not key then return end

          tooltip:SetText(B.Strings.KEY_BINDING_NAME_AND_KEY_TEXT:format(options.labelText, key))
          tooltip:AddLine(B.Strings.KEY_BINDING_TOOLTIP_TEXT)
        end
      })
      button:RegisterForClicks("AnyUp")

      --- Shows the key in white, or that there is none in grey.
      local function refresh()
        local key = options.get()
        button.label:SetText(key or L.NOT_BOUND)
        button:SetLabelColor(key and Colors.White or Colors.Grey)
        if button:GetEventValue("HOVERED") then button:UpdateTooltip() end
      end

      EventManager:On(E.StateUpdated, refresh)
      EventManager:On(E.KeybindingListeningChanged, function()
        button:FireEvent("FOCUSED", options.isListening())
      end)
      refresh()

      return button
    end
  })

  return root
end
