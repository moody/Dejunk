local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Default width and height of the item icon.
local DEFAULT_ICON_SIZE = 24

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemCardIconButtonOptions
--- @field icon string Texture of the icon.
--- @field highlightColor Color Fill color while hovered.
--- @field onClick fun(item: BagItem | ListItem) Called when the button is clicked.
--- @field onUpdateTooltip? fun(item: BagItem | ListItem, tooltip: Tooltip) Shown while hovering the button.
--- @field isEnabled? fun(item: BagItem | ListItem): boolean Disabled buttons are dimmed and pass the mouse to the card. Defaults to always enabled.

--- @class ItemCardComponentOptions
--- @field displayPrice? boolean Shows the price of the stack under the link. Defaults to `false`.
--- @field iconSize? integer Width and height of the icon. Defaults to `24`.
--- @field fontObject? Font Font of the link. Defaults to `B.FontObjects.Normal`.
--- @field iconButtons? ItemCardIconButtonOptions[] Adds a button at the right edge for each entry, the full height of the card.
--- @field onUpdateTooltip? fun(item: BagItem | ListItem, tooltip: Tooltip) Shown while hovering the card. Defaults to the item's tooltip.
--- @field onClick? fun(item: BagItem | ListItem, button: string) Called when the card is clicked with the left or right button.

-- =============================================================================
-- ComponentFactory - ItemCard
-- =============================================================================

--- Creates a card for an item, with a strip on the left edge in its quality color. Hidden until it has an item.
--- @param options ItemCardComponentOptions
--- @return ItemCardComponent root
function ComponentFactory:ItemCard(options)
  local frame ---@type FrameWidget?
  local accent ---@type Texture?
  local icon ---@type Texture?
  local item ---@type (BagItem | ListItem)?
  local isEnabled = true
  local accentR, accentG, accentB = 1, 1, 1
  local iconTexture ---@type (string | number)?

  --- Values last shown, to skip an item that has not changed.
  local shown = {}

  --- The component of each entry of `options.iconButtons`, and whether it last showed as enabled.
  --- @type { component: IconButtonComponent, isEnabled: boolean }[]
  local iconButtons = {}

  --- Brightens the card while hovered, if it has an item and is enabled.
  local function refreshBackdrop()
    if not frame then return end

    local isHighlighted = item and frame:GetEventValue("HOVERED") and frame:GetEventValue("ENABLED")
    frame:SetBackdropColor(Colors.White:GetRGBA(isHighlighted and 0.06 or 0.03))
  end

  --- Dims the card while it is disabled.
  local function refreshEnabled()
    if not frame then return end

    frame:SetAlpha(frame:GetEventValue("ENABLED") and 1 or 0.5)
    refreshBackdrop()

    -- A card under the mouse gets no new enter event, so refresh its tooltip.
    if frame:GetEventValue("HOVERED") then frame:UpdateTooltip() end
  end

  --- @class ItemCardComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    align = "CENTER",
    paddingLeft = ComponentFactory.CARD_ACCENT_WIDTH,
    visibility = "INVISIBLE",

    --- @param parent Frame
    frameFactory = function(parent)
      frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        tooltipAnchor = "ANCHOR_RIGHT",
        propagateWhenDisabled = true,

        --- @param tooltip Tooltip
        onUpdateTooltip = function(self, tooltip)
          if not item or not self:GetEventValue("ENABLED") then
            tooltip:Hide()
          elseif options.onUpdateTooltip then
            options.onUpdateTooltip(item, tooltip)
          else
            tooltip:SetHyperlink(item.link)
          end
        end
      })
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:OnEvent("HOVERED", refreshBackdrop)
      frame:OnEvent("ENABLED", refreshEnabled)
      refreshBackdrop()

      frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      frame:SetScript("OnClick", function(_, button)
        if item and options.onClick then options.onClick(item, button) end
      end)

      accent = frame:CreateTexture("$parent_Accent", "ARTWORK")
      accent:SetWidth(ComponentFactory.CARD_ACCENT_WIDTH)
      accent:SetPoint("TOPLEFT")
      accent:SetPoint("BOTTOMLEFT")
      accent:SetColorTexture(accentR, accentG, accentB)

      return frame
    end
  })

  -- Content, beside the accent strip.
  local content = root:AddRow({
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(0.5),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding()
  })

  -- Icon.
  content:AddChild({
    width = options.iconSize or DEFAULT_ICON_SIZE,
    height = options.iconSize or DEFAULT_ICON_SIZE,

    --- @param parent Frame
    frameFactory = function(parent)
      icon = parent:CreateTexture(nil, "ARTWORK")
      icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      icon:SetTexture(iconTexture)
      return icon
    end
  })

  -- With a price, the link and price are stacked in a column.
  local linkParent = content

  --- Price of the stack.
  --- @type TextComponent?
  local priceText
  if options.displayPrice then
    local textColumn = content:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })
    linkParent = textColumn:AddRow({ height = "AUTO", align = "CENTER" })
    priceText = textColumn:AddRow({ height = "AUTO", align = "CENTER" }):AttachComponent(ComponentFactory:Text({
      fontObject = B.FontObjects.Small,
      wordWrap = false,
      truncationTooltip = false
    }))
  end

  -- Item link and quantity.
  local title = linkParent:AttachComponent(ComponentFactory:Text({
    fontObject = options.fontObject,
    wordWrap = false,
    truncationTooltip = false
  }))

  -- Icon buttons, the full height of the card.
  for i, buttonOptions in ipairs(options.iconButtons or {}) do
    local component = root:AttachComponent(ComponentFactory:IconButton({
      icon = buttonOptions.icon,
      highlightColor = buttonOptions.highlightColor,
      width = ComponentFactory.CARD_BUTTON_WIDTH,
      tooltipAnchor = "ANCHOR_RIGHT",
      onClick = function()
        if item then buttonOptions.onClick(item) end
      end,
      onUpdateTooltip = buttonOptions.onUpdateTooltip and function(self, tooltip)
        if item and self:GetEventValue("ENABLED") then buttonOptions.onUpdateTooltip(item, tooltip) end
      end
    }))

    component:WhenFrameReady(function(buttonFrame)
      buttonFrame:PropagateWhenDisabled(true)
      buttonFrame:OnEvent("ENABLED", function(isButtonEnabled)
        buttonFrame:SetAlpha(isButtonEnabled and 1 or 0.3)
      end)
    end)

    iconButtons[i] = { component = component, isEnabled = true }
  end

  --- Enables or disables each icon button for the given item, if its state changed.
  --- @param newItem BagItem | ListItem
  local function refreshIconButtons(newItem)
    for i, button in ipairs(iconButtons) do
      local isEnabledFunc = options.iconButtons[i].isEnabled
      local isButtonEnabled = isEnabledFunc == nil or isEnabledFunc(newItem)

      if isButtonEnabled ~= button.isEnabled then
        button.isEnabled = isButtonEnabled
        button.component:WhenFrameReady(function(buttonFrame)
          buttonFrame:FireEvent("ENABLED", isButtonEnabled)

          -- A button under the mouse gets no new enter event, so refresh its tooltip.
          if buttonFrame:GetEventValue("HOVERED") then buttonFrame:UpdateTooltip() end
        end)
      end
    end
  end

  --- Dims the card and passes the mouse to the frame behind it while disabled. Cards start enabled.
  --- @param enabled boolean
  function root:SetEnabled(enabled)
    if enabled == isEnabled then return end
    isEnabled = enabled

    self:WhenFrameReady(function(readyFrame)
      readyFrame:FireEvent("ENABLED", enabled)
    end)
  end

  --- Shows the item, or hides the card if it has none. Call it again to refresh the item.
  --- @param newItem? BagItem | ListItem
  function root:SetItem(newItem)
    item = newItem

    if not newItem then
      shown.link = nil
      root:SetVisibility("INVISIBLE")
      refreshBackdrop()
      return
    end

    root:SetVisibility("VISIBLE")
    refreshBackdrop()
    refreshIconButtons(newItem)

    local quantity = newItem.quantity or 1
    --- @type number?
    local stackPrice
    if priceText and not newItem.noValue then stackPrice = newItem.price * quantity end

    local isChanged = (
      newItem.link ~= shown.link or
      quantity ~= shown.quantity or
      stackPrice ~= shown.price or
      newItem.texture ~= shown.texture or
      newItem.quality ~= shown.quality
    )
    if not isChanged then return end

    shown.link = newItem.link
    shown.quantity = quantity
    shown.price = stackPrice
    shown.texture = newItem.texture
    shown.quality = newItem.quality

    title:SetText(newItem.link .. (quantity > 1 and Colors.White("x" .. quantity) or ""))
    if priceText then priceText:SetText(stackPrice and Colors.White(B.Money:GetCoinText(stackPrice)) or "") end

    -- Icon.
    iconTexture = newItem.texture
    if icon then icon:SetTexture(iconTexture) end

    -- Quality strip.
    accentR, accentG, accentB = (Colors.ByQuality[newItem.quality] or Colors.QualityCommon):GetRGB()
    if accent then accent:SetColorTexture(accentR, accentG, accentB) end

    -- A card under the mouse gets no new enter event when its item changes, so refresh its tooltip.
    if frame and frame:GetEventValue("HOVERED") then frame:UpdateTooltip() end
  end

  return root
end
