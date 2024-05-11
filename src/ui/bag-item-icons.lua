local ADDON_NAME, Addon = ...
local E = Addon:GetModule("Events") ---@type Events
local EventManager = Addon:GetModule("EventManager") ---@type EventManager
local JunkFilter = Addon:GetModule("JunkFilter")
local TickerManager = Addon:GetModule("TickerManager") ---@type TickerManager

--- @class BagItemIcons
--- @field total integer
--- @field active table<BagItemIcon, boolean>
--- @field inactive table<BagItemIcon, boolean>
local bagItemIcons = {
  total = 0,
  active = {},
  inactive = {}
}

local junkItems = {}

--- Retrieves an icon from the inactive pool or creates a new one.
--- @return BagItemIcon
local function getBagItemIcon()
  local bagItemIcon = next(bagItemIcons.inactive)

  if bagItemIcon then
    bagItemIcons.inactive[bagItemIcon] = nil
  else
    bagItemIcons.total = bagItemIcons.total + 1

    --- @class BagItemIcon : Frame
    bagItemIcon = CreateFrame("Frame", ADDON_NAME .. "_BagItemIcon" .. bagItemIcons.total)

    -- Background texture.
    bagItemIcon.background = bagItemIcon:CreateTexture(nil, "BACKGROUND")
    bagItemIcon.background:SetAllPoints()
    bagItemIcon.background:SetColorTexture(0, 0, 0, 0.3)

    -- Overlay texture.
    bagItemIcon.overlay = bagItemIcon:CreateTexture(nil, "OVERLAY")
    bagItemIcon.overlay:SetAllPoints()
    bagItemIcon.overlay:SetTexture(Addon:GetAsset("dejunk-icon"))
  end

  bagItemIcons.active[bagItemIcon] = true

  return bagItemIcon
end

--- Resets the given icon and places it into the inactive icon pool.
--- @param bagItemIcon BagItemIcon
local function releaseBagItemIcon(bagItemIcon)
  bagItemIcons.active[bagItemIcon] = nil
  bagItemIcons.inactive[bagItemIcon] = true
  bagItemIcon:ClearAllPoints()
  bagItemIcon:SetParent(nil)
  bagItemIcon:Hide()
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

--- Updates icons for bag items based on their junk status.
local function updateBagIcons()
  for icon in pairs(bagItemIcons.active) do releaseBagItemIcon(icon) end

  local searchText = (BagItemSearchBox and BagItemSearchBox:GetText() or ""):lower()
  JunkFilter:GetJunkItems(junkItems)

  for _, item in pairs(junkItems) do
    if searchText == "" then
      local bagItemIcon = getBagItemIcon()
      local containerFrame = getContainerFrame(item.bag, item.slot)
      bagItemIcon:SetParent(containerFrame)
      bagItemIcon:SetPoint("TOPLEFT", 2, -2)
      bagItemIcon:SetPoint("BOTTOMRIGHT", -2, 2)
      bagItemIcon:Show()
    end
  end
end

-- Register events.
EventManager:Once(E.StoreCreated, function()
  local debounce = TickerManager:NewDebouncer(0.1, updateBagIcons)

  EventManager:On(E.BagsUpdated, debounce)
  EventManager:On(E.Wow.ItemLocked, debounce)
  EventManager:On(E.Wow.ItemUnlocked, debounce)

  EventManager:On(E.StateUpdated, updateBagIcons)
  EventManager:On(E.Wow.InventorySearchUpdate, updateBagIcons)
end)
