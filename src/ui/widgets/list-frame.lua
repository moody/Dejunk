local _, Addon = ...
local L = Addon:GetModule("Locale")
local TransportFrame = Addon:GetModule("TransportFrame")
local Widgets = Addon:GetModule("Widgets")

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
  local otherList = options.list:GetSibling()

  function options.onUpdateTooltip(self, tooltip)
    tooltip:SetText(options.titleText)
    tooltip:AddLine(options.descriptionText)
    tooltip:AddLine(" ")
    tooltip:AddLine(L.LIST_FRAME_TOOLTIP)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_TRANSPORT_FRAME)
    tooltip:AddDoubleLine(L.CTRL_ALT_RIGHT_CLICK, L.REMOVE_ALL_ITEMS)
  end

  function options.itemButtonOnUpdateTooltip(self, tooltip)
    tooltip:SetHyperlink(self.item.link)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L.RIGHT_CLICK, L.REMOVE)
    tooltip:AddDoubleLine(L.SHIFT_RIGHT_CLICK, L.ADD_TO_LIST:format(otherList.name))
  end

  function options.itemButtonOnClick(self, button)
    if button == "RightButton" then
      if IsShiftKeyDown() then
        otherList:Add(self.item.id)
      else
        options.list:Remove(self.item.id)
      end
    end
  end

  function options.getItems()
    return options.list:GetItems()
  end

  function options.addItem(itemId)
    return options.list:Add(itemId)
  end

  function options.removeAllItems()
    return options.list:RemoveAll()
  end

  -- Base frame.
  local frame = self:ItemsFrame(options)

  frame.titleButton:HookScript("OnClick", function(self, button)
    if button == "LeftButton" then
      TransportFrame:Toggle(options.list)
    end
  end)

  return frame
end
