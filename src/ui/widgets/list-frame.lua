local _, Addon = ...
local L = Addon.Locale
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
    tooltip:AddLine(options.descriptionText .. "|n|n" .. L.LIST_FRAME_TOOLTIP)
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
  return self:ItemsFrame(options)
end
