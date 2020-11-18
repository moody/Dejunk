local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Core = Addon.Core
local GameTooltip = _G.GameTooltip
local ItemWindow = Addon.UI.ItemWindow
local L = Addon.Libs.L
local UI = Addon.UI
local Widgets = Addon.UI.Widgets

-- ============================================================================
-- Local Functions
-- ============================================================================

local function handleItem(item)
  ItemWindow.service:HandleNextItem(item)
  -- Hide ItemWindow if there are no more items.
  if #ItemWindow.service:GetItems() == 0 then ItemWindow:Hide() end
end

-- ============================================================================
-- Functions
-- ============================================================================

function ItemWindow:IsShown()
  return self.frame and self.frame:IsShown()
end


function ItemWindow:Toggle(service)
  if self:IsShown() and self.service == service then
    self:Hide()
  else
    self:Show(service)
  end
end


function ItemWindow:Show(service)
  assert(service == Addon.Dejunker or service == Addon.Destroyer)
  -- Create the frame if necessary.
  if not self.frame then self:Create() end
  -- Set service.
  self.service = service
  -- Force OnUpdate.
  self.dirty = true
  self:OnUpdate(0)
  -- Hide tooltip in case the help button tooltip is shown.
  GameTooltip:Hide()
  -- Hide main UI before showing.
  UI:Hide()
  self.frame:Show()
end


function ItemWindow:Hide()
  if self.frame then self.frame:Hide() end
end


function ItemWindow:Create()
  local frame = AceGUI:Create("Window")
  frame:SetTitle(AddonName)
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
        (
          self.service == Addon.Dejunker and
          L.ITEM_WINDOW_LEFT_CLICK_TO_SELL or
          L.ITEM_WINDOW_LEFT_CLICK_TO_DESTROY
        ),
        L.ITEM_WINDOW_DRAG_DROP_TO_INCLUDE:format(
          self.service:GetLists().inclusions.locale
        ),
        L.ITEM_WINDOW_RIGHT_CLICK_TO_EXCLUDE:format(
          self.service:GetLists().exclusions.locale
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

  -- Add button.
  self.button = Widgets:Button({
    parent = frame,
    fullWidth = true,
    onClick = function() handleItem() end
  })

  -- Set OnUpdate script.
  frame.frame:SetScript("OnUpdate", function(_, elapsed)
    self:OnUpdate(elapsed)
  end)

  -- This function should only be called once.
  self.Create = nil
end


function ItemWindow:OnUpdate(elapsed)
  self.timer = (self.timer or 0) + elapsed
  -- Update if dirty, otherwise every 0.1 seconds.
  if self.dirty or self.timer >= 0.1 then
    self.timer = 0

    if self.dirty then
      self.dirty = false

      -- Set frame title.
      self.frame:SetTitle(
        AddonName .. " " .. (
          self.service == Addon.Dejunker and L.SELL_TEXT or L.DESTROY_TEXT
        )
      )

      -- Set button text.
      self.button:SetText(
        self.service == Addon.Dejunker and
        L.SELL_NEXT_ITEM or
        L.DESTROY_NEXT_ITEM
      )

      -- Update listFrame data.
      self.itemFrame:SetData({
        lists = self.service:GetLists(),
        items = self.service:GetItems(),
        handleItem = handleItem
      })
    end

    -- Refresh items.
    self.service:RefreshItems()
  end

  -- Disable button if Core:IsBusy() or service has no items.
  self.button:SetDisabled(Core:IsBusy() or #self.service:GetItems() == 0)
end

-- ============================================================================
-- Hook "CloseSpecialWindows" to hide UI when Esc is pressed
-- ============================================================================

local closeSpecialWindows = _G.CloseSpecialWindows
_G.CloseSpecialWindows = function()
  local found = closeSpecialWindows()

  if ItemWindow:IsShown() then
    ItemWindow:Hide()
    return true
  end

  return found
end
