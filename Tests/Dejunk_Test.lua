--[[
Copyright 2017 Justin Moody

Dejunk is distributed under the terms of the GNU General Public License.
You can redistribute it and/or modify it under the terms of the license as
published by the Free Software Foundation.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this addon. If not, see <http://www.gnu.org/licenses/>.

This file is part of Dejunk.
--]]

local AddonName, DJ = ...

-- Libs
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

-- Dejunk
local Test = DJ.Test

local Colors = DJ.Colors
local Consts = DJ.Consts
local ListManager = DJ.ListManager
local FramePooler = DJ.FramePooler

local ParentFrame = DJ.DejunkFrames.ParentFrame

--[[
//*******************************************************************
//  					    			   Slash Commands
//*******************************************************************
--]]

SLASH_DEJUNKTEST1 = "/dejunktest"
SlashCmdList["DEJUNKTEST"] = function(msg, editBox)
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")

  -- No input, print list of functions
  if (#cmd == 0) then
    print("Dejunk Test Functions:")
    for k, v in pairs(Test) do
      if (type(v) == "function") then
        print(k) end
    end

    return
  end

  -- Extract args
  local args = {}
  for arg in rest:gmatch("([^%s]+)") do
    args[#args+1] = arg end

  if (type(Test[cmd]) == "function") then
    Test[cmd](Test, unpack(args))
  else
    error("Unrecognized command.")
  end
end

--[[
//*******************************************************************
//  					    			       UI Tests
//*******************************************************************
--]]

function Test:Stats()
  local printColor = function(s, c)
    print(DJ.Tools:GetColorString(s, c))
  end

  local printStats = function(data)
    local name, count, pool = unpack(data)
    printColor(name.." created: "..count, Colors:GetColor(Colors.LabelText))
    printColor(name.." in pool: "..#pool, Colors:GetColor(Colors.Exclusions))
    printColor(name.." in play: "..(count - #pool), Colors:GetColor(Colors.Inclusions))
    print("")
  end

  print("")
  printColor("DEJUNK TEST STATS:", {1, 1, 1})
  print("")

  printStats({"Frames", FramePooler.FrameCount, FramePooler.FramePool})
  printStats({"Buttons", FramePooler.ButtonCount, FramePooler.ButtonPool})
  printStats({"CheckButtons", FramePooler.CheckButtonCount, FramePooler.CheckButtonPool})
  printStats({"Textures", FramePooler.TextureCount, FramePooler.TexturePool})
  printStats({"FontStrings", FramePooler.FontStringCount, FramePooler.FontStringPool})
  printStats({"ScrollFrames", FramePooler.ScrollFrameCount, FramePooler.ScrollFramePool})
  printStats({"Sliders", FramePooler.SliderCount, FramePooler.SliderPool})
  printStats({"EditBoxes", FramePooler.EditBoxCount, FramePooler.EditBoxPool})

  printColor("END DEJUNK TEST STATS.", {1, 1, 1})
  print("")
end

function Test:SetColor(colorScheme)
  if not colorScheme then
    print("SetColor(colorScheme)")
    return
  end

  Colors:SetColorScheme(colorScheme)
  ParentFrame:Refresh()
end

function Test:Init()
  ParentFrame:Initialize()
  ParentFrame:SetCurrentChild(DJ.DejunkFrames.BasicChildFrame)
end

function Test:Deinit()
  ParentFrame:Deinitialize()
end

--[[
//*******************************************************************
//                            List Tests
//*******************************************************************
--]]

function Test:Add(listName, rangeStart, rangeEnd)
  if not (listName or rangeStart or rangeEnd) then
    print("Add(listName, rangeStart, rangeEnd)")
    return
  end

  for i=rangeStart, rangeEnd do
    ListManager:AddToList(listName, i) end
end

function Test:Remove(listName, rangeStart, rangeEnd)
  if not (listName or rangeStart or rangeEnd) then
    print("Remove(listName, rangeStart, rangeEnd)")
    return
  end

  for i=rangeStart, rangeEnd do
    ListManager:RemoveFromList(listName, i) end
end

function Test:ListSize()
  print(format("Size of Inclusions: %s", #ListManager.Lists.Inclusions))
  print(format("Size of Exclusions: %s", #ListManager.Lists.Exclusions))
end

--[[
//*******************************************************************
//                           Filter Tests
//*******************************************************************
--]]

local function GetSellableItems()
  local items = {}

  for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local itemID = GetContainerItemID(bag, slot)

      if itemID then -- bag slot is not empty (seems to be guaranteed)
        local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(itemID)

        if name and (vendorPrice > 0) then
          local item = {}
          item.Name = name
          item.Link = link
          item.Quality = quality
          item.ItemLevel = iLevel
          item.RequiredLevel = reqLevel
          item.Class = class
          item.SubClass = subclass
          item.MaxStack = MaxStack
          item.EquipSlot = equipSlot
          item.Texture = texture
          item.Price = vendorPrice
          items[#items+1] = item
        end
      end
    end
  end

  return items
end

local function PrintItem(title, item)
  print(format("%s: %s", title, item.Link))
  print("Class: "..item.Class)
  print("SubClass: "..item.SubClass)
  print("Equip Slot: "..item.EquipSlot)
  print("")
end

function Test:Consumables()
  local items = GetSellableItems()
  local found = false

  -- We need to just create a "IsConsumable(item)" function
  for k, item in pairs(items) do
    if (item.Class == Consts.CONSUMABLE_CLASS or item.Class == "Glyph") then
      if (item.Quality ~= LE_ITEM_QUALITY_POOR) then
        PrintItem("Consumable", item)
        found = true
      end
    end
  end

  if not found then
    print("No consumables found.") end
end

function Test:TradeGoods()
  local items = GetSellableItems()
  local found = false

  -- We need to just create a "IsConsumable(item)" function
  for k, item in pairs(items) do
    local tradeGood = (item.Class == Consts.TRADEGOODS_CLASS) or (item.Class == Consts.GEM_CLASS)
    if tradeGood then
      PrintItem("Trade Good", item)
      found = true
    end
  end

  if not found then
    print("No trade goods found.") end
end

function Test:Unsuitables()
  local items = GetSellableItems()
  local found = false

  for k, item in pairs(items) do
    if (item.Class == Consts.ARMOR_CLASS) then
      local subclass = Consts.ARMOR_SUBCLASSES[item.SubClass]
      local suitable = (Consts.SUITABLE_ARMOR[subclass] or (item.EquipSlot == "INVTYPE_CLOAK"))

      if not suitable then
        PrintItem("Unsuitable", item)
        found = true
      end
    elseif (item.Class == Consts.WEAPON_CLASS) then
      local subclass = Consts.WEAPON_SUBCLASSES[item.SubClass]
      local suitable = Consts.SUITABLE_WEAPONS[subclass]

      if not suitable then
        PrintItem("Unsuitable", item)
        found = true
      end
    end
  end

  if not found then
    print("No unsuitables found.") end
end

function Test:GearTypes()
  local p = function(name, types)
    print(format("Localized Class Name: %s", name))

    for k, v in pairs(types) do
      print(format("[\"%s\"] = %s", k, v))
    end

    print("")
  end

  p(Consts.ARMOR_CLASS, Consts.ARMOR_SUBCLASSES)
  p(Consts.WEAPON_CLASS, Consts.WEAPON_SUBCLASSES)
end

function Test:ClassData()
  for class, data in pairs(Consts.CLASS_DATA) do
    print("Class: "..class)
    print("Armor: "..data.Armor)
    print("Weapon Skills:")

    for k, v in pairs(data.Weapons) do
      print(format("[%s] = %s", k, tostring(v))) end

    print("")
  end
end
