local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local JunkFilter = Addon:GetModule("JunkFilter")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")

--- @class ItemIcons
--- @field total integer
--- @field active table<ItemIcon, boolean>
--- @field inactive table<ItemIcon, boolean>
--- @field plugins table<string, ItemIconPlugin>
local itemIcons = {
  total = 0,
  active = {},
  inactive = {},
  plugins = {}
}

local junkItems = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

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
    itemIcon.background:SetColorTexture(0, 0, 0, 0.75)

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

--- Refreshes bag item icons based on item junk status.
local function refreshIcons()
  for icon in pairs(itemIcons.active) do releaseItemIcon(icon) end
  if not StateManager:GetGlobalState().itemIcons then return end

  JunkFilter:GetJunkItems(junkItems)

  for pluginName, plugin in pairs(itemIcons.plugins) do
    if plugin.isEnabled() then
      -- Addon:Debug(("Refreshing icons for %s."):format(pluginName))
      local searchText = plugin.getSearchText() or ""
      for _, item in pairs(junkItems) do
        if searchText == "" then
          local frame = plugin.getBagSlotFrame(item.bag, item.slot)
          if frame then
            local itemIcon = getItemIcon()
            itemIcon:SetParent(frame)
            itemIcon:SetAllPoints()
            itemIcon:Show()
          end
        end
      end
    end
  end
end

-- ============================================================================
-- Events
-- ============================================================================

EventManager:Once(E.StoreCreated, function()
  local debounce = TickerManager:NewDebouncer(0.1, refreshIcons)

  EventManager:On(E.BagsUpdated, debounce)
  EventManager:On(E.Wow.ItemLocked, debounce)
  EventManager:On(E.Wow.ItemUnlocked, debounce)

  EventManager:On(E.StateUpdated, refreshIcons)
  EventManager:On(E.Wow.InventorySearchUpdate, refreshIcons)

  EventRegistry:RegisterCallback("ContainerFrame.OpenBag", debounce)
  EventRegistry:RegisterCallback("ContainerFrame.OpenAllBags", debounce)
end)

-- ============================================================================
-- Plugins
-- ============================================================================

--- @class ItemIconPlugin
--- @field isEnabled fun(): boolean
--- @field getSearchText fun(): string
--- @field getBagSlotFrame fun(bag: integer, slot: integer): Frame | nil

--- Adds a plugin that will be evaluated whenever `refreshIcons()` is called.
--- @param plugin ItemIconPlugin
local function addPlugin(plugin)
  itemIcons.plugins[plugin.name] = plugin
end

--- Returns `true` if plugin with the given name is enabled.
--- @param pluginName string
--- @return boolean
local function isPluginEnabled(pluginName)
  return itemIcons.plugins[pluginName] and itemIcons.plugins[pluginName].isEnabled()
end

-- Default user interface.
addPlugin({
  name = "Default",
  isEnabled = function()
    return not (
      _G.Baganator or
      isPluginEnabled("ArkInventory") or
      isPluginEnabled("Bagnon") or
      isPluginEnabled("ElvUI")
    )
  end,
  getSearchText = function()
    return _G.BagItemSearchBox and _G.BagItemSearchBox:GetText() or ""
  end,
  getBagSlotFrame = function(bag, slot)
    if Addon.IS_RETAIL then
      return ContainerFrameUtil_GetItemButtonAndContainer(bag, slot)
    end

    local containerBag = bag + 1
    local containerSlot = C_Container.GetContainerNumSlots(bag) - slot + 1
    return _G[("ContainerFrame%sItem%s"):format(containerBag, containerSlot)]
  end
})

-- ArkInventory.
addPlugin({
  name = "ArkInventory",
  isEnabled = function()
    return _G.ArkInventory ~= nil
  end,
  getSearchText = function()
    return ""
  end,
  getBagSlotFrame = function(bag, slot)
    return _G[("ARKINV_Frame1ScrollContainerBag%sItem%s"):format(bag + 1, slot)]
  end
})

-- Bagnon.
addPlugin({
  name = "Bagnon",
  isEnabled = function()
    return (
      _G.Bagnon ~= nil and
      _G.BagnonInventory1 ~= nil and
      not isPluginEnabled("ArkInventory")
    )
  end,
  getSearchText = function()
    return ""
  end,
  getBagSlotFrame = function(bag, slot)
    local inventory = _G.BagnonInventory1
    local itemGroup = inventory and inventory.ItemGroup
    local buttons = itemGroup and itemGroup.buttons
    if buttons and buttons[bag] then
      local frame = buttons[bag][slot]
      if frame and frame.SetParent then
        return frame
      end
    end
  end
})

-- ElvUI.
addPlugin({
  name = "ElvUI",
  isEnabled = function()
    if _G.ElvUI ~= nil and not (isPluginEnabled("ArkInventory") or isPluginEnabled("Bagnon")) then
      local engine = _G.ElvUI[1]
      return (
        engine.private.bags.enable or
        not (engine.private.skins.blizzard.enable and engine.private.skins.blizzard.bags)
      )
    end
    return false
  end,
  getSearchText = function()
    return _G.ElvUI_ContainerFrameEditBox and _G.ElvUI_ContainerFrameEditBox:GetText() or ""
  end,
  getBagSlotFrame = function(bag, slot)
    bag = Addon.IS_RETAIL and bag or (bag - 1)
    return _G[("ElvUI_ContainerFrameBag%sSlot%s"):format(bag, slot)]
  end
})
