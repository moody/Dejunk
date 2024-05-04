local _, Addon = ...
local Colors = Addon:GetModule("Colors") ---@type Colors
local L = Addon:GetModule("Locale") ---@type Locale
local TransportFrame = Addon:GetModule("TransportFrame")
local Widgets = Addon:GetModule("Widgets") ---@class Widgets

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ListFrameWidgetOptions : ItemsFrameWidgetOptions
--- @field list table
--- @field getListSearchState fun(): ListSearchState

-- =============================================================================
-- Widgets - List Frame
-- =============================================================================

--- Creates an ItemsFrame for displaying a List.
--- @param options ListFrameWidgetOptions
--- @return ListFrameWidget frame
function Widgets:ListFrame(options)
  -- Defaults.
  options.titleText = options.list.name

  function options.onUpdateTooltip(self, tooltip)
    tooltip:SetText(options.list.name)
    tooltip:AddLine(options.list.description)
    tooltip:AddLine(" ")
    tooltip:AddLine(L.LIST_FRAME_TOOLTIP)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(Addon:Concat("+", L.CONTROL_KEY, L.ALT_KEY, L.RIGHT_CLICK), L.REMOVE_ALL_ITEMS)
  end

  function options.itemButtonOnUpdateTooltip(self, tooltip)
    tooltip:SetHyperlink(self.item.link)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L.RIGHT_CLICK, L.REMOVE)
    tooltip:AddDoubleLine(
      Addon:Concat("+", L.SHIFT_KEY, L.RIGHT_CLICK),
      L.ADD_TO_LIST:format(options.list:GetOpposite().name)
    )
    tooltip:AddDoubleLine(
      Addon:Concat("+", L.CONTROL_KEY, L.RIGHT_CLICK),
      L.ADD_TO_LIST:format(options.list:GetSibling():GetOpposite().name)
    )
    tooltip:AddDoubleLine(
      Addon:Concat("+", L.ALT_KEY, L.RIGHT_CLICK),
      L.ADD_TO_LIST:format(options.list:GetSibling().name)
    )
  end

  function options.itemButtonOnClick(self, button)
    if button == "RightButton" then
      if IsShiftKeyDown() then
        options.list:GetOpposite():Add(self.item.id)
      elseif IsControlKeyDown() then
        options.list:GetSibling():GetOpposite():Add(self.item.id)
      elseif IsAltKeyDown() then
        options.list:GetSibling():Add(self.item.id)
      else
        options.list:Remove(self.item.id)
      end
    end
  end

  function options.getItems()
    local searchState = options.getListSearchState()
    if searchState.isSearching and searchState.searchText ~= "" then
      return options.list:GetSearchItems(searchState.searchText)
    end

    return options.list:GetItems()
  end

  function options.addItem(itemId)
    return options.list:Add(itemId)
  end

  function options.removeAllItems()
    return options.list:RemoveAll()
  end

  -- Base frame.
  local frame = self:ItemsFrame(options) ---@class ListFrameWidget : ItemsFrameWidget
  frame.title:SetJustifyH("LEFT")

  -- Transport button.
  frame.transportButton = self:TitleFrameIconButton({
    name = "$parent_TransportButton",
    parent = frame.titleButton,
    points = { { "TOPRIGHT" }, { "BOTTOMRIGHT" } },
    texture = Addon:GetAsset("transport-icon"),
    textureSize = frame.title:GetStringHeight(),
    highlightColor = Colors.Yellow,
    onClick = function() TransportFrame:Toggle(options.list) end,
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(L.TRANSPORT)
      tooltip:AddLine(L.LIST_FRAME_TRANSPORT_BUTTON_TOOLTIP)
    end
  })

  return frame
end
