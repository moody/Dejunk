local _, Addon = ...
local L = Addon.Locale
local Widgets = Addon.UserInterface.Widgets

--[[
  Creates a fake scrolling frame for displaying list items.

  options = {
    name? = string,
    parent? = UIObject,
    points? = table[],
    width? = number,
    height? = number,
    titleText? = string,
    tooltipText = string,
    list = table
  }
]]
function Widgets:ListFrame(options)
  -- Defaults.
  options.tooltipText = options.tooltipText .. "|n|n" .. L.LIST_FRAME_TOOLTIP

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
