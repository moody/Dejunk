local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Width of the quality strip on the card's left edge.
local ACCENT_WIDTH = 3

--- Default width and height of the item icon.
local DEFAULT_ICON_SIZE = 24

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemCardComponentOptions
--- @field displayPrice? boolean Shows the price of the stack at the right edge. Defaults to `false`.
--- @field iconSize? integer Width and height of the icon. Defaults to `24`.
--- @field fontObject? Font Font of the link and price. Defaults to `B.FontObjects.Normal`.
--- @field onUpdateTooltip? fun(item: BagItem | ListItem, tooltip: Tooltip) Shown while hovering the card. Defaults to the item's tooltip.
--- @field onClick? fun(item: BagItem | ListItem, button: string) Called when the card is clicked with the left or right button.

-- =============================================================================
-- ComponentFactory - ItemCard
-- =============================================================================

--- Creates a one-line card for an item, with a strip on the left edge in its quality color. Hidden until it has an
--- item.
--- @param options ItemCardComponentOptions
--- @return ItemCardComponent root
function ComponentFactory:ItemCard(options)
  local frame ---@type FrameWidget?
  local accent ---@type Texture?
  local icon ---@type Texture?
  local item ---@type (BagItem | ListItem)?
  local accentR, accentG, accentB = 1, 1, 1
  local iconTexture ---@type (string | number)?

  --- Values last shown, to skip an item that has not changed.
  local shown = {}

  --- Brightens the card while hovered, if it has an item.
  local function refreshBackdrop()
    if not frame then return end

    local isHighlighted = item and frame:GetEventValue("HOVERED")
    frame:SetBackdropColor(Colors.White:GetRGBA(isHighlighted and 0.06 or 0.03))
  end

  --- @class ItemCardComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    align = "CENTER",
    paddingLeft = ACCENT_WIDTH,
    visibility = "INVISIBLE",

    --- @param parent Frame
    frameFactory = function(parent)
      frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        tooltipAnchor = "ANCHOR_RIGHT",

        --- @param tooltip Tooltip
        onUpdateTooltip = function(_, tooltip)
          if not item then
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
      refreshBackdrop()

      frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      frame:SetScript("OnClick", function(_, button)
        if item and options.onClick then options.onClick(item, button) end
      end)

      accent = frame:CreateTexture("$parent_Accent", "ARTWORK")
      accent:SetWidth(ACCENT_WIDTH)
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

  -- Item link and quantity.
  local title = content:AttachComponent(ComponentFactory:Text({
    fontObject = options.fontObject,
    wordWrap = false,
    truncationTooltip = false
  }))

  --- Price of the stack.
  --- @type TextComponent?
  local priceText
  if options.displayPrice then
    priceText = content:AttachComponent(ComponentFactory:Text({
      fontObject = options.fontObject,
      justifyH = "RIGHT",
      wordWrap = false,
      truncationTooltip = false,
      width = "AUTO"
    }))
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

    title:SetText(newItem.link .. (quantity > 1 and " " .. Colors.White("x" .. quantity) or ""))
    if priceText then priceText:SetText(stackPrice and Colors.White(B.Money:GetCoinText(stackPrice)) or "") end

    -- Icon.
    iconTexture = newItem.texture
    if icon then icon:SetTexture(iconTexture) end

    -- Quality strip.
    accentR, accentG, accentB = (Colors.ByQuality[newItem.quality] or Colors.QualityCommon):GetRGB()
    if accent then accent:SetColorTexture(accentR, accentG, accentB) end

    -- A card under the mouse gets no new enter event when its item changes, so refresh its tooltip.
    if frame and frame:IsVisible() and frame:IsMouseOver() then frame:UpdateTooltip() end
  end

  return root
end
