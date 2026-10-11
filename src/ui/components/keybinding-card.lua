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
--- @field onClick fun(mouseButton: string) Called when the card is clicked with any mouse button.

-- =============================================================================
-- ComponentFactory - KeybindingCard
-- =============================================================================

--- Creates a full-width card with a label and a box showing the bound key, or
--- that there is none. Clicking anywhere on it calls `onClick`.
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
      local frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        tooltipAnchor = "ANCHOR_RIGHT",

        --- Shows the binding and its key, or nothing while there is no key.
        onUpdateTooltip = function(_, tooltip)
          local key = options.get()
          if not key then return end

          tooltip:SetText(B.Strings.KEY_BINDING_NAME_AND_KEY_TEXT:format(options.labelText, key))
          tooltip:AddLine(B.Strings.KEY_BINDING_TOOLTIP_TEXT)
        end
      })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.03))
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      -- Brighten the fill while hovered.
      frame:OnEvent("HOVERED", function(isHovered)
        frame:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.06 or 0.03))
      end)

      -- Forward clicks to `onClick`, unless disabled.
      frame:HookScript("OnMouseUp", function(_, mouseButton, upInside)
        if upInside and frame:GetEventValue("ENABLED") then options.onClick(mouseButton) end
      end)

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
      --- @class KeybindingBoxWidget : FrameWidget
      --- @field label FontString
      local box = Widgets:Frame({ parent = parent })

      box.label = box:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
      box.label:SetPoint("LEFT", box, Widgets:Padding(0.5), 0)
      box.label:SetPoint("RIGHT", box, -Widgets:Padding(0.5), 0)
      box.label:SetWordWrap(false)

      -- Pass the mouse through to the card, which handles clicks.
      box:SetPropagateMouseClicks(true)
      box:SetPropagateMouseMotion(true)

      return box
    end
  }):WhenFrameReady(function(box)
    --- @cast box KeybindingBoxWidget
    --- @type FrameWidget
    local card = root:GetFrame()

    --- Shows the key, or that there is none, and colors the box to match the card's state.
    local function refresh()
      local key = options.get()
      local isHovered = card:GetEventValue("HOVERED")

      box.label:SetText(key or L.NOT_BOUND)

      if not box:GetEventValue("ENABLED") then
        box.label:SetTextColor(Colors.Grey:GetRGBA(0.5))
      else
        box.label:SetTextColor((key and Colors.White or Colors.Grey):GetRGBA(1))
      end

      if options.isListening() then
        box:SetBackdropColor(Colors.Yellow:GetRGBA(0.12))
        box:SetBackdropBorderColor(Colors.Yellow:GetRGBA(1))
      else
        box:SetBackdropColor(Colors.Black:GetRGBA(isHovered and 0.25 or 0.35))
        box:SetBackdropBorderColor(Colors.White:GetRGBA(isHovered and 0.25 or 0.1))
      end

      if isHovered then card:UpdateTooltip() end
    end

    card:OnEvent("HOVERED", refresh)
    box:OnEvent("ENABLED", refresh)
    EventManager:On(E.StateUpdated, refresh)
    EventManager:On(E.KeybindingListeningChanged, refresh)
  end)

  return root
end
