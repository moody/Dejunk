local ADDON_NAME, Addon = ...
local E = Addon:GetModule("Events") ---@type Events
local EventManager = Addon:GetModule("EventManager") ---@type EventManager
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager") ---@type StateManager
local TickerManager = Addon:GetModule("TickerManager") ---@type TickerManager

--- @class ItemIcons
--- @field total integer
--- @field active table<ItemIcon, boolean>
--- @field inactive table<ItemIcon, boolean>
local itemIcons = {
  total = 0,
  active = {},
  inactive = {}
}

local junkItems = {}

--- Retrieves an icon from the inactive pool or creates a new one.
--- @return ItemIcon
local function getItemIcon()
  local itemIcon = next(itemIcons.inactive)

  if itemIcon then
    itemIcons.inactive[itemIcon] = nil
  else
    itemIcons.total = itemIcons.total + 1

    --- @class ItemIcon : Frame
    itemIcon = CreateFrame("Frame", ADDON_NAME .. "_ItemIcon" .. itemIcons.total)

    -- Background texture.
    itemIcon.background = itemIcon:CreateTexture("$parent_BackgroundTexture", "BACKGROUND")
    itemIcon.background:SetAllPoints()
    itemIcon.background:SetColorTexture(0, 0, 0, 0.3)

    -- Overlay texture.
    itemIcon.overlay = itemIcon:CreateTexture("$parent_OverlayTexture", "OVERLAY")
    itemIcon.overlay:SetAllPoints()
    itemIcon.overlay:SetTexture(Addon:GetAsset("dejunk-icon"))
  end

  itemIcons.active[itemIcon] = true

  return itemIcon
end

--- Resets the given icon and places it into the inactive icon pool.
--- @param itemIcon ItemIcon
local function releaseItemIcon(itemIcon)
  itemIcons.active[itemIcon] = nil
  itemIcons.inactive[itemIcon] = true
  itemIcon:ClearAllPoints()
  itemIcon:SetParent(nil)
  itemIcon:Hide()
end

--- Attempts to retrieve the item frame for the given bag and slot.
--- @param bag integer
--- @param slot integer
--- @return Frame | nil
local function getContainerFrame(bag, slot)
  local containerBag = bag + 1
  local containerSlot = C_Container.GetContainerNumSlots(bag) - slot + 1
  return _G[("ContainerFrame%sItem%s"):format(containerBag, containerSlot)]
end

--- Refreshes bag item icons based on item junk status.
local function refreshIcons()
  for icon in pairs(itemIcons.active) do releaseItemIcon(icon) end
  if not StateManager:GetCurrentState().itemIcons then return end

  local searchText = (_G.BagItemSearchBox and _G.BagItemSearchBox:GetText() or ""):lower()
  JunkFilter:GetJunkItems(junkItems)

  for _, item in pairs(junkItems) do
    if searchText == "" then
      local itemIcon = getItemIcon()
      local containerFrame = getContainerFrame(item.bag, item.slot)
      itemIcon:SetParent(containerFrame)
      itemIcon:SetPoint("TOPLEFT", 2, -2)
      itemIcon:SetPoint("BOTTOMRIGHT", -2, 2)
      itemIcon:Show()
    end
  end
end

-- Register events.
EventManager:Once(E.StoreCreated, function()
  local debounce = TickerManager:NewDebouncer(0.1, refreshIcons)

  EventManager:On(E.BagsUpdated, debounce)
  EventManager:On(E.Wow.ItemLocked, debounce)
  EventManager:On(E.Wow.ItemUnlocked, debounce)

  EventManager:On(E.StateUpdated, refreshIcons)
  EventManager:On(E.Wow.InventorySearchUpdate, refreshIcons)
end)
