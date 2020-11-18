local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local UI = Addon.UI
local ItemWindow = Addon.UI.ItemWindow
local L = Addon.Libs.L
local Widgets = Addon.UI.Widgets

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
  if not self.frame then self:Create() end

  -- Set service.
  self.service = service

  -- Refresh items.
  service:RefreshItems()

  -- Set items.
  self.itemFrame:SetItems(service:GetItems())

  -- Set frame title and button text.
  local serviceText =
    service == Addon.Dejunker and
    L.SELL_TEXT or
    L.DESTROY_TEXT

  self.frame:SetTitle(("%s %s"):format(AddonName, serviceText))
  self.button:SetText(("%s %s"):format(serviceText, 'Next Item (L)'))

  -- Set button callback.
  self.button:SetCallback("OnClick", function()
    service:HandleNextItem()
    -- Hide ItemWindow if there are no more items.
    if #service:GetItems() == 0 then self:Hide() end
  end)

  -- Set button OnUpdate script.
  self.button.frame:SetScript("OnUpdate", function()
    self.button:SetDisabled(Addon.Core:IsBusy() or #service:GetItems() == 0)
  end)

  -- Hide main UI before showing.
  UI:Hide()
  self.frame:Show()
end

function ItemWindow:Hide()
  if self.frame then self.frame:Hide() end
end

function ItemWindow:Create()
  local frame = AceGUI:Create("Window")
  frame:SetTitle("ItemWindow")
  frame:SetWidth(350)
  frame:SetHeight(400)
  frame.frame:SetMinResize(350, 400)
  frame:SetLayout("Flow")
  self.frame = frame

  -- Add help label.
  self.helpLabel = Widgets:Label({
    parent = frame,
    text = 'Right-Click an item to exclude it (L).',
    fullWidth = true
  })

  -- Add ItemFrame widget.
  self.itemFrame = Widgets:ItemFrame({ parent = frame })

  -- Add button.
  self.button = Widgets:Button({
    parent = frame,
    text = '',
    fullWidth = true
  })

  -- Set OnUpdate script.
  local timer = 0
  frame.frame:SetScript("OnUpdate", function(_, elapsed)
    timer = timer + elapsed
    -- Refresh items once per second.
    if timer >= 1 then
      timer = 0
      if self.service then
        self.service:RefreshItems()
      end
    end
  end)

  -- This function should only be called once.
  self.Create = nil
end

do -- Hook "CloseSpecialWindows" to hide UI when Esc is pressed
  local closeSpecialWindows = _G.CloseSpecialWindows
  _G.CloseSpecialWindows = function()
    local found = closeSpecialWindows()

    if ItemWindow:IsShown() then
      ItemWindow:Hide()
      return true
    end

    return found
  end
end
