local _, Addon = ...
local Colors = Addon.Colors
local GameTooltip = GameTooltip
local Sounds = Addon.Sounds
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a fake scrolling frame for displaying items.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    numButtons? = number,
    titleText? = string,
    tooltipText = string,
    getItems = function() -> table[],
    addItem = function(itemId: string) -> nil,
    removeItem = function(itemId: string) -> nil,
    removeAllItems = function() -> nil
  }
]]
function Widgets:ItemsFrame(options)
  local SPACING = Widgets:Padding()

  -- Defaults.
  options.titleTemplate = nil
  options.titleJustify = "CENTER"
  options.numButtons = options.numButtons or 8

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.options = options
  frame.buttons = {}

  -- Title button.
  frame.titleButton = CreateFrame("Button", "$parent_TitleButton", frame)
  frame.titleButton:SetPoint("TOPLEFT", frame.titleBackground)
  frame.titleButton:SetPoint("BOTTOMRIGHT", frame.titleBackground)
  frame.titleButton:RegisterForClicks("RightButtonUp")

  function frame.titleButton:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(options.titleText)
    GameTooltip:AddLine(options.tooltipText, 1, 0.82, 0, true)
    GameTooltip:Show()
  end

  frame.titleButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" and IsControlKeyDown() and IsAltKeyDown() then
      Sounds.Click()
      options.removeAllItems()
    end
  end)

  frame.titleButton:SetScript("OnEnter", function(self)
    self:UpdateTooltip()
  end)

  frame.titleButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Slider.
  frame.slider = self:Frame({
    name = "$parent_Slider",
    frameType = "Slider",
    parent = frame,
    points = {
      { "TOPRIGHT", frame.titleBackground, "BOTTOMRIGHT", -SPACING, -SPACING },
      { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -SPACING, SPACING }
    },
    width = 12
  })

  frame.slider:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
  frame.slider:SetBackdropBorderColor(Colors.DarkGrey:GetRGBA(0.5))

  frame.slider:SetObeyStepOnDrag(true)
  frame.slider:SetOrientation("VERTICAL")
  frame.slider:SetValueStep(1)
  frame.slider:SetMinMaxValues(1, 1)
  frame.slider:SetValue(1)

  -- Slider thumb texture.
  frame.slider.texture = frame.slider:CreateTexture("$parent_Texture", "ARTWORK")
  frame.slider.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
  frame.slider.texture:SetSize(frame.slider:GetWidth(), frame.slider:GetWidth() * 2)
  frame.slider:SetThumbTexture(frame.slider.texture)

  -- Buttons.
  for i = 1, options.numButtons do
    frame.buttons[#frame.buttons + 1] = self:ItemButton({
      name = "$parent_ItemButton" .. i,
      parent = frame,
    })
  end

  -- No items text.
  frame.noItemsText = frame:CreateFontString("$parent_NoItemsText", "ARTWORK", "GameFontNormal")
  frame.noItemsText:SetPoint("CENTER")
  frame.noItemsText:SetText(Colors.White(Addon.Locale.NO_ITEMS))
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

  frame:SetScript("OnUpdate", function(self)
    local items = options.getItems()

    -- Update buttons.
    for i, button in ipairs(self.buttons) do
      local sliderOffset = math.floor(self.slider:GetValue() + 0.5)
      local item = items[i + sliderOffset]
      if item then
        button:SetItem(item)
        button:Show()
      else
        button:Hide()
      end

      -- Points.
      if i == 1 then
        button:SetPoint("TOPLEFT", self.titleBackground, "BOTTOMLEFT", SPACING, -SPACING)
        button:SetPoint("TOPRIGHT", self.slider, "TOPLEFT", -SPACING, 0)
      else
        button:SetPoint("TOPLEFT", self.buttons[i - 1], "BOTTOMLEFT", 0, -SPACING)
        button:SetPoint("TOPRIGHT", self.buttons[i - 1], "BOTTOMRIGHT", 0, -SPACING)
      end

      -- Height.
      local buttonArea = self:GetHeight() - self.titleBackground:GetHeight() - (SPACING * 2)
      local buttonSpacing = (options.numButtons - 1) * SPACING
      button:SetHeight((buttonArea - buttonSpacing) / options.numButtons)
    end

    -- Update slider values.
    local maxVal = max((#items - #self.buttons), 0)
    self.slider:SetMinMaxValues(0, maxVal)
    if maxVal == 0 then
      self.slider:Hide()
      self.buttons[1]:SetPoint("TOPRIGHT", self.titleBackground, "BOTTOMRIGHT", -SPACING, -SPACING)
    else
      self.slider:Show()
      self.buttons[1]:SetPoint("TOPRIGHT", self.slider, "TOPLEFT", -SPACING, 0)
    end

    -- Update "No items." text.
    if #items == 0 then
      self.noItemsText:Show()
    else
      self.noItemsText:Hide()
    end
  end)

  return frame
end

--[[
  Creates a button for displaying an item in an ItemsFrame.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number
  }
]]
function Widgets:ItemButton(options)
  -- Defaults.
  options.frameType = "Button"

  -- Base frame.
  local frame = self:Frame(options)
  frame:RegisterForClicks("RightButtonUp")
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

  function frame:OnUpdate()
    if not self.item then return end
    -- Icon.
    local size = self:GetHeight() - Widgets:Padding()
    self.icon:SetSize(size, size)
    self.icon:SetTexture(self.item.texture)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    -- Text.
    local quantity = self.item.quantity or 1
    self.text:SetText(self.item.link .. (quantity > 1 and Colors.White("x" .. quantity) or ""))
  end

  function frame:SetItem(item)
    self.item = item
    self:OnUpdate()
    if GetMouseFocus() == self then
      self:UpdateTooltip()
    end
  end

  function frame:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if self.item.bag and self.item.slot then
      GameTooltip:SetBagItem(self.item.bag, self.item.slot)
    else
      GameTooltip:SetHyperlink(self.item.link)
    end
    GameTooltip:Show()
  end

  frame:SetScript("OnEnter", function(self)
    -- Add highlight.
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.5))
    -- Show tooltip.
    self:UpdateTooltip()
  end)

  frame:SetScript("OnLeave", function(self)
    -- Remove highlight.
    self:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
    self:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))
    -- Hide tooltip.
    GameTooltip:Hide()
  end)

  frame:SetScript("OnMouseDown", function(self)
    self:GetParent():AddCursorItem()
  end)

  frame:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      Sounds.Click()
      self:GetParent().options.removeItem(self.item.id)
    end
  end)

  frame:SetScript("OnUpdate", frame.OnUpdate)

  return frame
end
