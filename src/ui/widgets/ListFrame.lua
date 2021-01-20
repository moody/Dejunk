local _, Addon = ...
local Type, Version = "Dejunk_ListFrame", 1
local AceGUI = Addon.Libs.AceGUI
if (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Upvalues
local ClearCursor = _G.ClearCursor
local CreateFrame = _G.CreateFrame
local CursorHasItem = _G.CursorHasItem
local DCL = Addon.Libs.DCL
local DressUpVisual = _G.DressUpVisual
local floor = math.floor
local GameTooltip = _G.GameTooltip
local GetCursorInfo = _G.GetCursorInfo
local GetMouseFocus = _G.GetMouseFocus
local IsControlKeyDown = _G.IsControlKeyDown
local IsDressableItem = _G.IsDressableItem
local max = math.max
local UIParent = _G.UIParent
local unpack = _G.unpack

-- Consts
local PAD_X, PAD_Y = 4, 16
local BUTTON_SPACING = 0 -- math.floor(PAD_Y * 0.25 + 0.5)
local BUTTON_ICON_SIZE = 22
local BUTTON_HEIGHT = BUTTON_ICON_SIZE + 10
local NUM_LIST_BUTTONS = 8

-- ============================================================================
-- Widget Mixins
-- ============================================================================

local widgetMixins = {}

-- Reset stuff to defaults
function widgetMixins:OnAcquire()
  self:SetHeight(
    BUTTON_HEIGHT * NUM_LIST_BUTTONS +
    BUTTON_SPACING * (NUM_LIST_BUTTONS - 1)
  )
end

-- Clear stuff
function widgetMixins:OnRelease()
  self.frame.list = nil
  self.frame.scrollBar.list = nil
end

function widgetMixins:SetList(list)
  self.frame.offset = 0
  self.frame.list = list
  self.frame.scrollBar.list = list
  self.frame.scrollBar:SetMinMaxValues(0, max(#list.items - NUM_LIST_BUTTONS, 0))
  self.frame.scrollBar:SetValue(0)
end

-- ============================================================================
-- Frame
-- ============================================================================

local frameMixins, frameScripts = {}, {}

function frameMixins:AddCursorItem()
  if CursorHasItem() then
    local infoType, itemID = GetCursorInfo()

    if (infoType == "item") then
      self.list:Add(itemID)
    end

    ClearCursor()
  end
end

function frameMixins:RemoveItem(itemID)
  self.list:Remove(itemID)
end

function frameScripts:OnMouseUp()
  self:AddCursorItem()
end

function frameScripts:OnUpdate(elapsed)
  -- Update buttons
  for i, button in ipairs(self.buttons) do
    local index = (i + self.offset)
    local item = self.list.items[index]

    if item then
      button:Show()
      button:SetItem(item)
    else
      button:Hide()
    end
  end

  -- Update scroll bar values
  local maxVal = max((#self.list.items - #self.buttons), 0)
  self.scrollBar:SetMinMaxValues(0, maxVal)

  -- Update "No items." text
  if #self.list.items <= 0 then
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
  if #self.list.items <= NUM_LIST_BUTTONS then
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
  self.icon:SetTexture(item.Texture)
  self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  self.text:SetText(("[%s]"):format(item.Name))
  self.text:SetTextColor(unpack(DCL:GetColorByQuality(item.Quality)))
  if GetMouseFocus() == self then self:ShowTooltip() end
end

function ButtonScripts:OnClick(button)
  if (button == "LeftButton") then
    if IsControlKeyDown() then
      if IsDressableItem(self.item.ItemID) then
        DressUpVisual(self.item.ItemLink)
      end
    else
      self:GetParent():AddCursorItem()
    end
  elseif (button == "RightButton") then
    self:GetParent():RemoveItem(self.item.ItemID)
  end
end

function ButtonMixins:ShowTooltip()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetHyperlink(self.item.ItemLink)
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
      button:SetPoint("TOPLEFT", lastButton, "BOTTOMLEFT", 0, -BUTTON_SPACING)
      button:SetPoint("TOPRIGHT", lastButton, "BOTTOMRIGHT", 0, -BUTTON_SPACING)
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
  frame.noItemsText:SetText(Addon.Libs.L.NO_ITEMS_TEXT)
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
