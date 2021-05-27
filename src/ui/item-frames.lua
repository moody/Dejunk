local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Core = Addon.Core
local DB = Addon.DB
local floor = math.floor
local GetCoinTextureString = _G.GetCoinTextureString
local hooksecurefunc = _G.hooksecurefunc
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local type = type
local UI = Addon.UI
local unpack = _G.unpack
local Widgets = Addon.UI.Widgets

-- ============================================================================
-- Frame Mixins
-- ============================================================================

local ItemFrameMixins = {}


function ItemFrameMixins:IsShown()
  return self.frame and self.frame:IsShown()
end


function ItemFrameMixins:Toggle()
  if self:IsShown() then self:Hide() else self:Show() end
end


function ItemFrameMixins:Show()
  -- Stop if already shown.
  if self:IsShown() then return end
  -- Create the frame if necessary.
  if not self.frame then self:Create() end
  -- Set dirty flag.
  self.dirty = true
  -- Hide main UI before showing.
  UI:Hide()
  self.frame:Show()
end


function ItemFrameMixins:Hide()
  if self.frame then self.frame:Hide() end
end


function ItemFrameMixins:Create()
  local frame = AceGUI:Create("Window")
  frame.frame:SetFrameStrata("MEDIUM")
  frame:SetTitle(self.options.title)
  frame:SetWidth(350)
  frame:SetHeight(370)
  frame:EnableResize(false)
  frame:SetLayout("Flow")
  self.frame = frame

  do -- Set point.
    local success = pcall(function()
      frame:ClearAllPoints()
      frame:SetPoint(unpack(self.options.getPoint()))
    end)

    if not success then
      -- Revert to default point.
      self.options.setPoint(nil)
      frame:ClearAllPoints()
      frame:SetPoint(unpack(self.options.defaultPoint))
    end
  end

  -- Add help label.
  Widgets:Label({
    parent = frame,
    text = L.ITEM_WINDOW_DRAG_DROP_TO_INCLUDE:format(
      self.options.service:GetLists().inclusions.profile.locale
    ),
    fullWidth = true,
  })

  -- Add space.
  Widgets:Label({ parent = frame, text = " ", fullWidth = true })

  -- Add ItemFrame widget.
  self.itemFrame = Widgets:ItemFrame({
    parent = frame,
    title = L.ITEM_WINDOW_CURRENT_ITEMS,
    data = {
      lists = self.options.service:GetLists(),
      items = self.options.service:GetItems(),
      handleItem = function(item)
        self.options.service:HandleNextItem(item)
      end,
      handleItemTooltip = self.options.handleItemTooltip
    }
  })

  -- Add total heading.
  self.totalHeading = Widgets:Heading(frame)

  -- Add button.
  self.button = Widgets:Button({
    parent = frame,
    fullWidth = true,
    height = 32,
    text = self.options.buttonText,
    onClick = function()
      if #self.options.service:GetItems() == 0 then
        self:Hide()
      else
        self.options.service:Start()
      end
    end,
  })

  -- Hook StopMovingOrSizing.
  hooksecurefunc(frame.frame, "StopMovingOrSizing", function(f)
    local point, _, _, x, y = f:GetPoint()
    self.options.setPoint({ point, floor(x + 0.5), floor(y + 0.5) })
  end)

  -- Set OnUpdate script.
  frame.frame:SetScript("OnUpdate", function(_, elapsed)
    -- Update every 0.1 seconds or if dirty.
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= 0.1 or self.dirty then
      self.timer = 0
      self.dirty = false

      -- Refresh items.
      self.options.service:RefreshItems()
      local items = self.options.service:GetItems()

      -- Set ItemFrame title.
      self.itemFrame.parent:SetTitle(
        ("%s (|cFFFFFFFF%s|r)"):format(L.ITEM_WINDOW_CURRENT_ITEMS, #items)
      )

      -- Update total heading.
      local total = 0
      for _, item in ipairs(items) do
        total = total + (item.Price * item.Quantity)
      end
      self.totalHeading:SetText(
        ("|cFFFFFFFF%s|r"):format(GetCoinTextureString(total))
      )
    end

    -- Update button.
    local isBusy, reason = Core:IsBusy()
    self.button:SetDisabled(isBusy)
    self.button:SetText(isBusy and reason or (
      #self.options.service:GetItems() == 0 and
      _G.CLOSE or
      self.options.buttonText
    ))
  end)

  -- Hook CloseSpecialWindows to hide when ESC is pressed.
  local closeSpecialWindows = _G.CloseSpecialWindows
  _G.CloseSpecialWindows = function()
    local found = closeSpecialWindows()

    if frame:IsShown() then
      frame:Hide()
      return true
    end

    return found
  end

  -- This function should only be called once.
  self.Create = nil
end

-- ============================================================================
-- Functions
-- ============================================================================

ItemFrames.frames = {}
ItemFrames.hiddenFrames = {}

-- Shows frames previously hidden by `HideAll`.
function ItemFrames:ReshowHidden()
  for frame, wasShown in pairs(self.hiddenFrames) do
    if wasShown then frame:Show() end
  end
end

-- Hides all item frames.
function ItemFrames:HideAll()
  for frame in pairs(self.frames) do
    self.hiddenFrames[frame] = frame:IsShown()
    frame:Hide()
  end
end

-- ============================================================================
-- Initialize Frames
-- ============================================================================

local function assertType(obj, objType, msg)
  assert(type(obj) == objType, msg)
end


local function init(frame, options)
  assertType(options, "table")
  assertType(options.title, "string")
  assertType(options.defaultPoint, "table")
  assertType(options.getPoint, "function")
  assertType(options.setPoint, "function")
  assertType(options.handleItemTooltip, "string")
  assertType(options.buttonText, "string")
  assertType(options.service, "table")
  assert(
    options.service == Addon.Dejunker or
    options.service == Addon.Destroyer
  )

  frame.options = options
  for k, v in pairs(ItemFrameMixins) do frame[k] = v end

  ItemFrames.frames[frame] = true
end

-- Sell Frame
init(ItemFrames.Sell, {
  title = AddonName .. " " .. L.SELL_TEXT,
  defaultPoint = { "CENTER", -200, 0 },
  getPoint = function() return DB.Global.sell.frame.point end,
  setPoint = function(point) DB.Global.sell.frame.point = point end,
  handleItemTooltip = L.SELL_TEXT,
  buttonText = L.START_SELLING_BUTTON_TEXT,
  service = Addon.Dejunker,
})


-- Destroy Frame
init(ItemFrames.Destroy, {
  title = AddonName .. " " .. L.DESTROY_TEXT,
  defaultPoint = { "CENTER", 200, 0 },
  getPoint = function() return DB.Global.destroy.frame.point end,
  setPoint = function(point) DB.Global.destroy.frame.point = point end,
  handleItemTooltip = L.DESTROY_TEXT,
  buttonText = L.START_DESTROYING,
  service = Addon.Destroyer,
})
