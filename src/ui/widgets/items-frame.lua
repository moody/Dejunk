local _, Addon = ...
local Colors = Addon.Colors
local GameTooltip = GameTooltip
local L = Addon.Locale
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a fake scrolling frame for displaying items.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string,
    tooltipText = string,
    getItems = function() -> table[],
    addItem = function(itemId: string) -> nil,
    removeItem = function(itemId: string) -> nil,
    removeAllItems = function() -> nil
  }
]]
function Widgets:ItemsFrame(options)
  -- Defaults.
  options.titleTemplate = nil
  options.titleJustify = "CENTER"
  options.titleBackground = true

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.options = options
  frame.buttons = {}

  local NUM_BUTTONS = 8
  local SPACING = self:Padding()
  local BUTTON_HEIGHT = (
      frame:GetHeight() - frame.titleBackground:GetHeight() - (SPACING * 2) - ((NUM_BUTTONS - 1) * SPACING)
      ) / NUM_BUTTONS

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
  for i = 1, NUM_BUTTONS do
    local points = i == 1 and
        {
          { "TOPLEFT", frame.titleBackground, "BOTTOMLEFT", SPACING, -SPACING },
          { "TOPRIGHT", frame.slider, "TOPLEFT", -SPACING, 0 }
        } or
        {
          { "TOPLEFT", frame.buttons[#frame.buttons], "BOTTOMLEFT", 0, -SPACING },
          { "TOPRIGHT", frame.buttons[#frame.buttons], "BOTTOMRIGHT", 0, -SPACING }
        }

    local button = self:ItemButton({
      name = "$parent_ItemButton" .. i,
      parent = frame,
      points = points,
      height = BUTTON_HEIGHT
    })

    frame.buttons[#frame.buttons + 1] = button
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
  local iconSize = frame:GetHeight() - self:Padding()
  frame.icon = frame:CreateTexture("$parent_Icon", "ARTWORK")
  frame.icon:SetPoint("LEFT", self:Padding(0.5), 0)
  frame.icon:SetSize(iconSize, iconSize)

  -- Item text.
  frame.text = frame:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormal")
  frame.text:SetPoint("LEFT", frame.icon, "RIGHT", self:Padding(0.5), 0)
  frame.text:SetPoint("RIGHT", frame, "RIGHT", -self:Padding(0.5), 0)
  frame.text:SetJustifyH("LEFT")
  frame.text:SetWordWrap(false)

  -- Sets the item that this button displays.
  function frame:SetItem(item)
    self.item = item
  end

  function frame:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetHyperlink(self.item.link)
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
      self:GetParent().options.removeItem(self.item.id)
    end
  end)

  frame:SetScript("OnUpdate", function(self)
    if not self.item then return end
    self.icon:SetTexture(self.item.texture)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local quantity = self.item.quantity or 1
    self.text:SetText(self.item.link .. (quantity > 1 and Colors.White("x" .. quantity) or ""))
  end)

  return frame
end
