local _, Addon = ...
local L = Addon.Locale
local Sounds = Addon.Sounds
local TransportFrame = Addon.UserInterface.TransportFrame
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates an ItemsFrame for displaying a list.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    numButtons? = number,
    displayPrice? = boolean,
    titleText = string,
    descriptionText = string,
    list = table
  }
]]
function Widgets:ListFrame(options)
  function options.onUpdateTooltip(self, tooltip)
    tooltip:SetText(options.titleText)
    tooltip:AddLine(options.descriptionText)
    tooltip:AddLine(" ")
    tooltip:AddLine(L.LIST_FRAME_TOOLTIP)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_TRANSPORT_FRAME)
    tooltip:AddDoubleLine(L.CTRL_ALT_RIGHT_CLICK, L.REMOVE_ALL_ITEMS)
  end

  function options.getItems()
    return options.list:GetItems()
  end

  function options.addItem(itemId)
    return options.list:Add(itemId)
  end

  function options.removeItem(itemId)
    return options.list:Remove(itemId)
  end

  function options.removeAllItems()
    return options.list:RemoveAll()
  end

  -- Base frame.
  local frame = self:ItemsFrame(options)

  frame.titleButton:HookScript("OnClick", function(self, button)
    if button == "LeftButton" then
      Sounds.Click()
      TransportFrame:Toggle(options.list)
    end
  end)

  return frame
end
