local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Core = Addon.Core
local GameTooltip = _G.GameTooltip
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local UI = Addon.UI
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
  -- Create the frame if necessary.
  if not self.frame then self:Create() end
  -- Refresh items.
  self.options.service:RefreshItems()
  -- Reset OnUpdate timer.
  self.timer = 0
  -- Hide tooltip in case the help button tooltip is shown.
  GameTooltip:Hide()
  -- Hide main UI before showing.
  UI:Hide()
  self.frame:Show()
end


function ItemFrameMixins:Hide()
  if self.frame then self.frame:Hide() end
end


function ItemFrameMixins:Create()
  local frame = AceGUI:Create("Window")
  frame:SetTitle(self.options.title)
  frame:SetWidth(350)
  frame:SetHeight(405)
  frame:EnableResize(false)
  frame:SetLayout("Flow")
  self.frame = frame

  -- Add help button.
  Widgets:Button({
    parent = frame,
    text = L.HELP_TEXT,
    fullWidth = true,
    onEnter = function(b)
      local line = ("%s|n|n%s|n|n%s"):format(
        self.options.helpTooltip,
        L.ITEM_WINDOW_DRAG_DROP_TO_INCLUDE:format(
          self.options.service:GetLists().inclusions.locale
        ),
        L.ITEM_WINDOW_RIGHT_CLICK_TO_EXCLUDE:format(
          self.options.service:GetLists().exclusions.locale
        )
      )
      GameTooltip:SetOwner(b.frame, "ANCHOR_TOP")
      GameTooltip:SetText(L.HELP_TEXT, 1.0, 0.82, 0)
      GameTooltip:AddLine(line, 1, 1, 1, true)
      GameTooltip:Show()
    end,
    onLeave = function()
      GameTooltip:Hide()
    end
  })

  -- Add ItemFrame widget.
  self.itemFrame = Widgets:ItemFrame({
    parent = frame,
    title = L.ITEM_WINDOW_CURRENT_ITEMS
  })
  self.itemFrame:SetData({
    lists = self.options.service:GetLists(),
    items = self.options.service:GetItems(),
    handleItem = function(item)
      self.options.service:HandleNextItem(item)
    end,
  })

  -- Add button.
  self.button = Widgets:Button({
    parent = frame,
    fullWidth = true,
    text = self.options.buttonText,
    onClick = function() self.options.service:HandleNextItem() end,
  })

  -- Set OnUpdate script.
  frame.frame:SetScript("OnUpdate", function(_, elapsed)
    -- Update every 0.1 seconds.
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= 0.1 then
      self.timer = 0
      self.options.service:RefreshItems()
    end

    -- Disable button if Core:IsBusy() or no items.
    self.button:SetDisabled(
      Core:IsBusy() or
      #self.options.service:GetItems() == 0
    )
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

function ItemFrames:HideAll()
  for frame in pairs(self.frames) do
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
  assertType(options.helpTooltip, "string")
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
  helpTooltip = L.ITEM_WINDOW_LEFT_CLICK_TO_SELL,
  buttonText = L.SELL_NEXT_ITEM,
  service = Addon.Dejunker,
})


-- Destroy Frame
init(ItemFrames.Destroy, {
  title = AddonName .. " " .. L.DESTROY_TEXT,
  helpTooltip = L.ITEM_WINDOW_LEFT_CLICK_TO_DESTROY,
  buttonText = L.DESTROY_NEXT_ITEM,
  service = Addon.Destroyer,
})
