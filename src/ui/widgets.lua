local ADDON_NAME, Addon = ...
local Colors = Addon.Colors
local GameTooltip = GameTooltip
local L = Addon.Locale
local Widgets = Addon.UserInterface.Widgets

local BORDER_BACKDROP = {
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Buttons\\WHITE8x8",
  tileEdge = false,
  edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

do -- Padding
  local PADDING = 8
  local cache = {}

  function Widgets:Padding(multiplier)
    if type(multiplier) ~= "number" then return PADDING end
    local value = cache[tostring(multiplier)]
    if not value then
      value = PADDING * multiplier
      cache[tostring(multiplier)] = value
    end
    return value
  end
end

--[[
  Creates a basic frame with a backdrop.

  options = {
    name? = string,
    frameType? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number
  }
]]
function Widgets:Frame(options)
  local frame = CreateFrame(options.frameType or "Frame", options.name, options.parent or UIParent)
  frame:SetClipsChildren(true)

  -- Backdrop.
  if not frame.SetBackdrop then
    Mixin(frame, BackdropTemplateMixin)
  end
  frame:SetBackdrop(BORDER_BACKDROP)
  frame:SetBackdropColor(0, 0, 0, 0.75)
  frame:SetBackdropBorderColor(0, 0, 0, 1)

  -- Options.
  if options.width then frame:SetWidth(options.width) end
  if options.height then frame:SetHeight(options.height) end
  if options.points then
    for _, point in ipairs(options.points) do
      frame:SetPoint(SafeUnpack(point))
    end
  end

  return frame
end

--[[
  Creates a basic frame with title text.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string,
    titleTemplate? = string,
    titleJustify? = "LEFT" | "RIGHT" | "CENTER",
    titleBackground? = boolean
  }
]]
function Widgets:TitleFrame(options)
  -- Defaults.
  options.frameType = "Frame"

  -- Base frame.
  local frame = self:Frame(options)

  -- Title text.
  frame.title = frame:CreateFontString("$parent_Title", "ARTWORK", options.titleTemplate or "GameFontNormal")
  frame.title:SetText(Colors.White(options.titleText or ADDON_NAME))

  if options.titleJustify == "LEFT" then
    frame.title:SetPoint("TOPLEFT", self:Padding(), -self:Padding())
  elseif options.titleJustify == "RIGHT" then
    frame.title:SetPoint("TOPRIGHT", -self:Padding(), -self:Padding())
  else
    frame.title:SetPoint("TOP", 0, -self:Padding())
  end

  -- Title background.
  if options.titleBackground then
    local titleHeight = max(frame.title:GetHeight(), frame.title:GetStringHeight()) + self:Padding(2)
    frame.titleBackground = frame:CreateTexture("$parent_TitleBackground")
    frame.titleBackground:SetColorTexture(Colors.DarkGrey:GetRGBA(0.75))
    frame.titleBackground:SetPoint("TOPLEFT", 1, -1)
    frame.titleBackground:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -1, -titleHeight - 1)
  end

  return frame
end

--[[
  Creates a moveable frame with title text and a close button.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string
  }
]]
function Widgets:Window(options)
  -- Defaults.
  options.points = options.points or { { "CENTER" } }
  options.width = options.width or 675
  options.height = options.height or 500
  options.titleText = options.titleText or ADDON_NAME
  options.titleTemplate = "GameFontNormalLarge"
  options.titleJustify = "LEFT"

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame:SetFrameStrata("FULLSCREEN_DIALOG")

  -- Make frame moveable.
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  -- Close button.
  frame.closeButton = CreateFrame("Button", "$parent_CloseButton", frame)
  frame.closeButton.text = frame.closeButton:CreateFontString("$parent_Text", "ARTWORK", "GameFontNormalLarge")
  frame.closeButton.text:SetText(Colors.White("X"))
  frame.closeButton:SetFontString(frame.closeButton.text)
  frame.closeButton:SetSize(frame.closeButton.text:GetWidth(), frame.closeButton.text:GetHeight())
  frame.closeButton:SetPoint("TOPRIGHT", -self:Padding(), -self:Padding())
  frame.closeButton:SetScript("OnEnter", function(self) self.text:SetText(Colors.Red("X")) end)
  frame.closeButton:SetScript("OnLeave", function(self) self.text:SetText(Colors.White("X")) end)
  frame.closeButton:SetScript("OnClick", function() frame:Hide() end)

  return frame
end

--[[
  Creates a TitleFrame with the ability to add check button options.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string
  }
]]
function Widgets:OptionsFrame(options)
  -- Defaults.
  options.titleTemplate = nil
  options.titleJustify = "CENTER"
  options.titleBackground = true

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.buttons = {}

  --[[
    -- Adds an option button to the frame.

    options = {
      labelText = string,
      tooltipText = string,
      get = function() -> boolean,
      set = function(value: boolean) -> nil
    }
  ]]
  function frame:AddOption(options)
    local CHECKBUTTONS_PER_ROW = 3
    local SPACING = Widgets:Padding()

    -- Defaults.
    options.name = "$parent_CheckButton" .. #self.buttons + 1
    options.parent = self
    options.width = math.floor(
      (self:GetWidth() - (SPACING * 2) - (CHECKBUTTONS_PER_ROW - 1) * SPACING) / CHECKBUTTONS_PER_ROW
    )
    options.height = self.title:GetHeight() + Widgets:Padding()

    -- Set `points` based on `#self.buttons` and `CHECKBUTTONS_PER_ROW`.
    if #self.buttons == 0 then
      options.points = { { "TOPLEFT", self.titleBackground, "BOTTOMLEFT", SPACING, -SPACING } }
    else
      local row = #self.buttons / CHECKBUTTONS_PER_ROW
      if math.floor(row) == row then
        local firstIndexOfPreviousRow = #self.buttons - (CHECKBUTTONS_PER_ROW - 1)
        options.points = { { "TOPLEFT", self.buttons[firstIndexOfPreviousRow], "BOTTOMLEFT", 0, -SPACING } }
      else
        options.points = { { "TOPLEFT", self.buttons[#self.buttons], "TOPRIGHT", SPACING, 0 } }
      end
    end

    -- Add button.
    self.buttons[#self.buttons + 1] = Widgets:OptionButton(options)
  end

  return frame
end

--[[
  Creates a toggleable option button.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height = number,
    labelText = string,
    tooltipText = string,
    get = function() -> boolean,
    set = function(value: boolean) -> nil
  }
]]
function Widgets:OptionButton(options)
  -- Defaults.
  options.frameType = "Button"

  -- Base frame.
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
  frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(Colors.White(options.labelText))
  frame.label:SetPoint("LEFT", frame, self:Padding(0.5), 0)
  frame.label:SetPoint("RIGHT", frame, self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)

  function frame:UpdateTooltip()
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(options.labelText, 1, 1, 1)
    GameTooltip:AddLine(options.tooltipText, 1, 0.82, 0, true)
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

  frame:SetScript("OnClick", function(self)
    options.set(not options.get())
  end)

  frame:SetScript("OnUpdate", function(self)
    self:SetAlpha(options.get() and 1 or 0.3)
  end)

  return frame
end

--[[
  Creates a fake scrolling frame for displaying list items.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string,
    descriptionText = string,
    list = table
  }
]]
function Widgets:ListFrame(options)
  -- Defaults.
  options.titleTemplate = nil
  options.titleJustify = "CENTER"
  options.titleBackground = true

  -- Base frame.
  local frame = self:TitleFrame(options)
  frame.list = options.list
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
    GameTooltip:AddLine(options.descriptionText .. "|n|n" .. L.LIST_FRAME_TOOLTIP, 1, 0.82, 0, true)
    GameTooltip:Show()
  end

  frame.titleButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" and IsControlKeyDown() and IsAltKeyDown() then
      frame.list:RemoveAll()
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

    local button = self:ListButton({
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
      if infoType == "item" then self.list:Add(itemId) end
      ClearCursor()
    end
  end

  frame:SetScript("OnMouseDown", frame.AddCursorItem)

  frame:SetScript("OnMouseWheel", function(self, delta)
    self.slider:SetValue(self.slider:GetValue() - delta)
  end)

  frame:SetScript("OnUpdate", function(self)
    for i, button in ipairs(self.buttons) do
      local sliderOffset = math.floor(self.slider:GetValue() + 0.5)
      local item = self.list:GetItems()[i + sliderOffset]
      if item then
        button:SetItem(item)
        button:Show()
      else
        button:Hide()
      end
    end

    -- Update slider values.
    local maxVal = max((#self.list:GetItems() - #self.buttons), 0)
    self.slider:SetMinMaxValues(0, maxVal)
    if maxVal == 0 then
      self.slider:Hide()
      self.buttons[1]:SetPoint("TOPRIGHT", self.titleBackground, "BOTTOMRIGHT", -SPACING, -SPACING)
    else
      self.slider:Show()
      self.buttons[1]:SetPoint("TOPRIGHT", self.slider, "TOPLEFT", -SPACING, 0)
    end

    if #self.list:GetItems() == 0 then
      self.noItemsText:Show()
    else
      self.noItemsText:Hide()
    end
  end)

  return frame
end

--[[
  Creates a list button for displaying an item in a list frame.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number
  }
]]
function Widgets:ListButton(options)
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
    GameTooltip:SetHyperlink("item:" .. self.item.id)
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
      frame:GetParent().list:Remove(self.item.id)
    end
  end)

  frame:SetScript("OnUpdate", function(self)
    if not self.item then return end
    self.icon:SetTexture(self.item.texture)
    self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    self.text:SetText(self.item.link)
  end)

  return frame
end
