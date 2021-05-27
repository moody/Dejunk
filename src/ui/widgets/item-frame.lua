local _, Addon = ...
local Type, Version = "Dejunk_ItemFrame", 1
local AceGUI = Addon.Libs.AceGUI
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Upvalues
local ClearCursor = _G.ClearCursor
local Colors = Addon.Colors
local CreateFrame = _G.CreateFrame
local CursorHasItem = _G.CursorHasItem
local DCL = Addon.Libs.DCL
local DressUpVisual = _G.DressUpVisual
local floor = math.floor
local GameTooltip = _G.GameTooltip
local GetCoinTextureString = _G.GetCoinTextureString
local GetCursorInfo = _G.GetCursorInfo
local GetMouseFocus = _G.GetMouseFocus
local IsControlKeyDown = _G.IsControlKeyDown
local IsDressableItem = _G.IsDressableItem
local IsShiftKeyDown = _G.IsShiftKeyDown
local L = Addon.Libs.L
local max = math.max
local UIParent = _G.UIParent

-- Consts
local PAD_X, PAD_Y = 4, 16
local BUTTON_ICON_SIZE = 22
local BUTTON_HEIGHT = BUTTON_ICON_SIZE + 10
local NUM_LIST_BUTTONS = 6

-- ============================================================================
-- Widget Mixins
-- ============================================================================

local widgetMixins = {}

-- Reset stuff to defaults
function widgetMixins:OnAcquire()
  self:SetHeight(BUTTON_HEIGHT * NUM_LIST_BUTTONS)
end

-- Clear stuff
function widgetMixins:OnRelease()
  self.frame.lists = nil
  self.frame.items = nil
  self.frame.handleItem = nil
  self.frame.handleItemTooltip = nil
  self.frame.scrollBar.items = nil
end

--[[
  data = {
    lists = table,
    items = table,
    handleItem = function,
    handleItemTooltip = string,
  }
]]
function widgetMixins:SetData(data)
  assert(type(data.lists) == "table")
  assert(type(data.items) == "table")
  assert(type(data.handleItem) == "function")
  assert(type(data.handleItemTooltip) == "string")
  self.frame.offset = 0
  self.frame.lists = data.lists
  self.frame.items = data.items
  self.frame.handleItem = data.handleItem
  self.frame.handleItemTooltip = data.handleItemTooltip
  self.frame.scrollBar.items = data.items
  self.frame.scrollBar:SetMinMaxValues(0, max(#data.items - NUM_LIST_BUTTONS, 0))
  self.frame.scrollBar:SetValue(0)
end

-- ============================================================================
-- Frame
-- ============================================================================

local frameMixins, frameScripts = {}, {}

function frameMixins:HandleItem(item)
  if CursorHasItem() then
    local infoType, itemID = GetCursorInfo()

    if (infoType == "item") then
      self.lists.inclusions.profile:Add(itemID)
    end

    ClearCursor()
  elseif item then
    self.handleItem(item)
  end
end

function frameScripts:OnMouseUp()
  self:HandleItem()
end

function frameMixins:ExcludeItem(itemID)
  self.lists.exclusions.profile:Add(itemID)
end

function frameScripts:OnUpdate(elapsed)
  -- Update buttons
  for i, button in ipairs(self.buttons) do
    local index = (i + self.offset)
    local item = self.items[index]

    if item then
      button:Show()
      button:SetItem(item)
    else
      button:Hide()
    end
  end

  -- Update scroll bar values
  local maxVal = max((#self.items - #self.buttons), 0)
  self.scrollBar:SetMinMaxValues(0, maxVal)

  -- Update "No items." text
  if #self.items <= 0 then
    self.noItemsText:Show()
  else
    self.noItemsText:Hide()
  end
end

function frameScripts:OnMouseWheel(delta)
  self.scrollBar:SetValue(self.scrollBar:GetValue() - delta)
end

-- ============================================================================
-- Scroll Bar Scripts
-- ============================================================================

local scrollBarScripts = {}

function scrollBarScripts:OnUpdate(elapsed)
  if #self.items <= NUM_LIST_BUTTONS then
    self.ScrollUpButton:Disable()
    self.ScrollDownButton:Disable()
  else
    self.ScrollUpButton:Enable()
    self.ScrollDownButton:Enable()
  end
end

function scrollBarScripts:OnValueChanged()
  self:GetParent().offset = floor(self:GetValue() + 0.5)
end

-- ============================================================================
-- Button
-- ============================================================================

local ButtonMixins, ButtonScripts = {}, {}

function ButtonMixins:SetItem(item)
  self.item = item
  self.itemText = (
    item.Quantity > 1 and
    (item.ItemLink .. "x" .. item.Quantity) or
    item.ItemLink
  )
  self.icon:SetTexture(item.Texture)
  self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  self.text:SetText(self.itemText)
  self.text:SetTextColor(1, 1, 1)
  if GetMouseFocus() == self then self:ShowTooltip() end
end

function ButtonScripts:OnClick(button)
  if IsShiftKeyDown() then return end

  if button == "LeftButton" then
    if IsControlKeyDown() then
      if IsDressableItem(self.item.ItemID) then
        DressUpVisual(self.item.ItemLink)
      end
    else
      self:GetParent():HandleItem(self.item)
    end
  elseif button == "RightButton" then
    self:GetParent():ExcludeItem(self.item.ItemID)
  end
end

function ButtonMixins:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")

  if IsShiftKeyDown() then
    GameTooltip:SetBagItem(self.item.Bag, self.item.Slot)
  else
    -- Set title to itemText.
    GameTooltip:SetText(self.itemText, 1, 1, 1)

    -- Add total.
    local total = GetCoinTextureString(self.item.Price * self.item.Quantity)
    GameTooltip:AddLine(("%s:  %s"):format(_G.SELL_PRICE, total), 1, 1, 1)

    -- Add reason.
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(DCL:ColorString(L.REASON_TEXT, Colors.Yellow))
    GameTooltip:AddLine("  " .. self.item.Reason, 1, 1, 1)

    -- Add left-click info.
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(
      L.LEFT_CLICK,
      self:GetParent().handleItemTooltip,
      nil, nil, nil,
      1, 1, 1
    )

    -- Add right-click info.
    GameTooltip:AddDoubleLine(
      L.RIGHT_CLICK,
      L.BINDINGS_ADD_TO_LIST_TEXT:format(
        self:GetParent().lists.exclusions.profile.locale
      ),
      nil, nil, nil,
      1, 1, 1
    )

    -- Add hold shift info.
    GameTooltip:AddDoubleLine(
      L.HOLD_SHIFT,
      L.ITEM_TOOLTIP_TEXT,
      nil, nil, nil,
      1, 1, 1
    )
  end

  -- Show.
  GameTooltip:Show()
end

function ButtonScripts:OnEnter()
  self.bg:SetColorTexture(1, 1, 1)
  self.bg:SetAlpha(0.1)
  self:ShowTooltip()
end

function ButtonScripts:OnLeave()
  self.bg:SetColorTexture(0, 0, 0)
  self.bg:SetAlpha(self.alpha)
  GameTooltip:Hide()
end

local function createButton(parent, index)
  local button = CreateFrame("Button", nil, parent)
  button.alpha = index % 2 == 0 and 0.2 or 0.4
  button:SetHeight(BUTTON_HEIGHT)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  -- Background
  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints()
  button.bg:SetColorTexture(0, 0, 0)
  button.bg:SetAlpha(button.alpha)

  -- Icon
  button.icon = button:CreateTexture(nil, "ARTWORK")
  button.icon:SetPoint("LEFT", 8, 0)
  button.icon:SetSize(BUTTON_ICON_SIZE, BUTTON_ICON_SIZE)
  button.icon:SetTexture(134400)

  -- Text
  button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.text:SetPoint("LEFT", button.icon, "RIGHT", 10, 0)
  button.text:SetPoint("RIGHT", -8, 0)
  button.text:SetWordWrap(false)
  button.text:SetJustifyH("LEFT")
  button.text:SetText("Remove later...")

  -- Mixins & Scripts
  for k, v in pairs(ButtonMixins) do button[k] = v end
  for k, v in pairs(ButtonScripts) do button:SetScript(k, v) end

  button:Hide()
  return button
end

-- ============================================================================
-- Constructor
-- ============================================================================

local function getScrollBar(frame, num)
	local scrollBar = CreateFrame(
    "Slider",
    ("AceConfigDialogScrollFrame%dScrollBar"):format(num),
    frame,
    "UIPanelScrollBarTemplate"
  )
	scrollBar:SetPoint("TOPRIGHT", frame, -PAD_X, -PAD_Y)
  scrollBar:SetPoint("BOTTOMRIGHT", frame, -PAD_X, PAD_Y)
  scrollBar:SetObeyStepOnDrag(true)
  scrollBar:SetValueStep(1)
  scrollBar:SetWidth(16)
  scrollBar.scrollStep = 1 -- important!

  do -- Skin with ElvUI
    local E = _G.ElvUI and _G.ElvUI[1] -- ElvUI Engine
    if E then E:GetModule("Skins"):HandleScrollBar(scrollBar) end
  end

  -- Background
  local scrollbg = scrollBar:CreateTexture(nil, "BACKGROUND")
	scrollbg:SetAllPoints()
  scrollbg:SetColorTexture(0, 0, 0, 0.4)

  -- Add scripts
  for k, v in pairs(scrollBarScripts) do scrollBar:SetScript(k, v) end

  return scrollBar
end

local function getButtons(frame, scrollBar)
  local buttons = {}

  for i=1, NUM_LIST_BUTTONS do
    local button = createButton(frame, i)
    local lastButton = buttons[#buttons]

    if lastButton then
      button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, 0)
      button:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, 0)
    else
      button:SetPoint("TOPLEFT", frame, PAD_X, 0)
      button:SetPoint("TOPRIGHT", scrollBar.ScrollUpButton, "TOPLEFT", -PAD_X, 0)
    end

    buttons[#buttons+1] = button
  end

  return buttons
end

local function Constructor()
  local num = AceGUI:GetNextWidgetNum(Type)
  local frame = CreateFrame("Frame", nil, UIParent)
  frame.scrollBar = getScrollBar(frame, num)
  frame.buttons = getButtons(frame, frame.scrollBar)
  frame.offset = 0

  -- No items text.
  frame.noItemsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.noItemsText:SetText(L.NO_ITEMS_TEXT)
  frame.noItemsText:SetTextColor(1, 1, 1)
  frame.noItemsText:SetAlpha(0.5)
  frame.noItemsText:SetPoint("CENTER")

  -- Add mixins & scripts
  for k, v in pairs(frameMixins) do frame[k] = v end
  for k, v in pairs(frameScripts) do frame:SetScript(k, v) end

  -- Create widget
	local widget = { type = Type, frame = frame }
  for k, v in pairs(widgetMixins) do widget[k] = v end

  -- Register and return
	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
