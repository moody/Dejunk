local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ItemsFrameWidgetOptions : TitleFrameWidgetOptions
--- @field itemButtonOnUpdateTooltip? fun(self: ItemButtonWidget, tooltip: Tooltip)
--- @field itemButtonOnClick? fun(self: ItemButtonWidget, button: string)
--- @field numButtons? integer
--- @field displayPrice? boolean
--- @field isItemEnabled? fun(item: ListItem): boolean
--- @field getItems fun(): ListItem[]
--- @field addItem fun(itemId: string)
--- @field removeAllItems fun()

--- @class ItemButtonWidgetOptions : FrameWidgetOptions
--- @field isItemEnabled? fun(item: ListItem): boolean
--- @field onClick? fun(self: ItemButtonWidget, button: string)
--- @field displayPrice? boolean

-- =============================================================================
-- Widgets - Items Frame
-- =============================================================================

--- Creates a fake scrolling frame for displaying items.
--- @param options ItemsFrameWidgetOptions
--- @return ItemsFrameWidget
function Widgets:ItemsFrame(options)
  local SPACING = Widgets:Padding()

  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("ItemsFrame"))
  options.titleTemplate = nil
  options.titleJustify = Addon:IfNil(options.titleJustify, "CENTER")
  options.numButtons = Addon:IfNil(options.numButtons, 7)

  --- @class ItemsFrameWidget : TitleFrameWidget
  local frame = self:TitleFrame(options)
  frame.buttons = {}

  frame.titleButton:SetScript("OnClick", function(_, button)
    if button == "RightButton" and IsControlKeyDown() and IsAltKeyDown() then
      options.removeAllItems()
    end
  end)

  -- Slider.
  frame.slider = self:Slider({
    name = "$parent_Slider",
    parent = frame,
    points = {
      { "TOPRIGHT", frame.titleButton, "BOTTOMRIGHT", -SPACING, -SPACING },
      { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -SPACING, SPACING }
    }
  })

  -- Buttons.
  for i = 1, options.numButtons do
    frame.buttons[#frame.buttons + 1] = self:ItemButton({
      name = "$parent_ItemButton" .. i,
      parent = frame,
      displayPrice = options.displayPrice,
      onUpdateTooltip = options.itemButtonOnUpdateTooltip,
      isItemEnabled = options.isItemEnabled,
      onClick = options.itemButtonOnClick
    })
  end

  -- No items text.
  frame.noItemsText = frame:CreateFontString("$parent_NoItemsText", "ARTWORK", "GameFontNormal")
  frame.noItemsText:SetPoint("CENTER")
  frame.noItemsText:SetText(Colors.White(L.NO_ITEMS))
  frame.noItemsText:SetAlpha(0.3)

  function frame:AddCursorItem()
    if CursorHasItem() then
      local infoType, itemId = GetCursorInfo()
      if infoType == "item" then options.addItem(itemId) end
      ClearCursor()
    end
  end

  frame:SetScript("OnMouseDown", frame.AddCursorItem)

  frame:SetScript("OnMouseWheel", function(self, delta)
    self.slider:SetValue(self.slider:GetValue() - delta)
  end)

  -- Ticker for updating UI.
  TickerManager:NewTicker(1 / 30, function()
    local items = options.getItems()

    -- Update buttons.
    for i, button in ipairs(frame.buttons) do
      local sliderOffset = math.floor(frame.slider:GetValue() + 0.5)
      local item = items[i + sliderOffset]
      if item then
        button:SetItem(item)
        button:Show()
      else
        button:Hide()
      end

      -- Points.
      if i == 1 then
        button:SetPoint("TOPLEFT", frame.titleButton, "BOTTOMLEFT", SPACING, -SPACING)
        button:SetPoint("TOPRIGHT", frame.slider, "TOPLEFT", -SPACING, 0)
      else
        button:SetPoint("TOPLEFT", frame.buttons[i - 1], "BOTTOMLEFT", 0, -SPACING)
        button:SetPoint("TOPRIGHT", frame.buttons[i - 1], "BOTTOMRIGHT", 0, -SPACING)
      end

      -- Height.
      local buttonArea = frame:GetHeight() - frame.titleButton:GetHeight() - (SPACING * 2)
      local buttonSpacing = (options.numButtons - 1) * SPACING
      button:SetHeight((buttonArea - buttonSpacing) / options.numButtons)
    end

    -- Update slider values.
    local maxVal = max((#items - #frame.buttons), 0)
    frame.slider:SetMinMaxValues(0, maxVal)
    if maxVal == 0 then
      frame.slider:Hide()
      frame.buttons[1]:SetPoint("TOPRIGHT", frame.titleButton, "BOTTOMRIGHT", -SPACING, -SPACING)
    else
      frame.slider:Show()
      frame.buttons[1]:SetPoint("TOPRIGHT", frame.slider, "TOPLEFT", -SPACING, 0)
    end

    -- Update "No items." text.
    if #items == 0 then
      frame.noItemsText:Show()
    else
      frame.noItemsText:Hide()
    end
  end):BindFrame(frame)

  return frame
end

-- =============================================================================
-- Widgets - Item Button
-- =============================================================================

--- Creates a button for displaying an item in an ItemsFrame.
--- @param options ItemButtonWidgetOptions
--- @return ItemButtonWidget frame
function Widgets:ItemButton(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("ItemButton"))
  options.frameType = "Button"
  options.onUpdateTooltip = Addon:IfNil(options.onUpdateTooltip, function(self, tooltip)
    tooltip:SetHyperlink(self.item.link)
  end)

  --- @class ItemButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

  -- Item icon.
  frame.icon = frame:CreateTexture("$parent_Icon", "ARTWORK")
  frame.icon:SetPoint("LEFT", self:Padding(0.5), 0)

  -- Item text.
  frame.text = frame:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormal")
  frame.text:SetPoint("LEFT", frame.icon, "RIGHT", self:Padding(0.5), 0)
  frame.text:SetPoint("RIGHT", frame, "RIGHT", -self:Padding(0.5), 0)
  frame.text:SetJustifyH("LEFT")
  frame.text:SetWordWrap(false)

  -- Price text.
  if options.displayPrice then
    frame.price = frame:CreateFontString("$parent_Price", "ARTWORK", "GameFontNormal")
    frame.price:SetPoint("RIGHT", frame, -self:Padding(0.5), 0)
    frame.price:SetJustifyH("RIGHT")
    frame.price:SetWordWrap(false)
    -- Update item text point.
    frame.text:SetPoint("RIGHT", frame.price, "LEFT", -self:Padding(0.5), 0)
  end

  --- @param item ListItem
  function frame:SetItem(item)
    self.item = item

    -- Icon.
    local size = frame:GetHeight() - Widgets:Padding()
    frame.icon:SetSize(size, size)
    frame.icon:SetTexture(item.texture)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Text.
    local quantity = item.quantity or 1
    frame.text:SetText(item.link .. (quantity > 1 and Colors.White("x" .. quantity) or ""))
    -- Price.
    if frame.price then
      local text = item.noValue and "" or Colors.White(GetCoinTextureString(item.price * quantity))
      frame.price:SetText(text)
    end
    -- Enabled.
    if options.isItemEnabled then
      local isEnabled = options.isItemEnabled(item)
      frame:SetEnabled(isEnabled)
      frame:SetAlpha(isEnabled and 1 or 0.3)
    end
  end

  frame:HookScript("OnEnter", function(self)
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
  end)

  frame:HookScript("OnLeave", function(self)
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
  end)

  frame:SetScript("OnClick", function(self, button)
    if CursorHasItem() then
      if button == "LeftButton" then
        self:GetParent():AddCursorItem()
      end
    elseif options.onClick then
      options.onClick(self, button)
    end
  end)

  return frame
end
