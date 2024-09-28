local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local ListItemParser = Addon:GetModule("ListItemParser")
local TransportFrame = Addon:GetModule("TransportFrame")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ListFrameWidgetOptions : ItemsFrameWidgetOptions
--- @field list List
--- @field getListSearchState fun(): ListSearchState

-- =============================================================================
-- Widgets - List Frame
-- =============================================================================

--- Creates an ItemsFrame for displaying a List.
--- @param options ListFrameWidgetOptions
--- @return ListFrameWidget frame
function Widgets:ListFrame(options)
  -- Defaults.
  options.name = Addon:IfNil(options.name, Widgets:GetUniqueName("ListFrame"))
  options.titleText = options.list.name
  options.titleJustify = "LEFT"

  function options.onUpdateTooltip(self, tooltip)
    tooltip:SetText(options.list.name)
    tooltip:AddLine(options.list.description)
    tooltip:AddLine(" ")
    tooltip:AddLine(L.LIST_FRAME_TOOLTIP)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(Addon:Concat("+", L.CONTROL_KEY, L.ALT_KEY, L.RIGHT_CLICK), L.REMOVE_ALL_ITEMS)
  end

  function options.itemButtonOnUpdateTooltip(self, tooltip)
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
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

  function options.isItemEnabled(item)
    return options.list:Contains(item.id)
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

  --- @class ListFrameWidget : ItemsFrameWidget
  local frame = self:ItemsFrame(options)

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

  -- Spinner button.
  frame.spinnerButton = self:TitleFrameIconButton({
    name = "$parent_SpinnerButton",
    parent = frame.titleButton,
    points = {
      { "TOPRIGHT", frame.transportButton, "TOPLEFT", 0, 0 },
      { "BOTTOMRIGHT", frame.transportButton, "BOTTOMLEFT", 0, 0 }
    },
    texture = Addon:GetAsset("spinner-icon"),
    textureSize = frame.title:GetStringHeight(),
    highlightColor = Colors.Blue,
    onClick = nil,
    onUpdateTooltip = function(self, tooltip)
      local percentage = options.list:GetParsedItemPercentage()
      tooltip:SetText(("%s: %s%%"):format(L.LOADING, Colors.Blue(percentage)))
    end
  })

  local spinnerAnimGroup = frame.spinnerButton.texture:CreateAnimationGroup()
  spinnerAnimGroup:SetLooping("REPEAT")

  local rotationAnim = spinnerAnimGroup:CreateAnimation("Rotation")
  rotationAnim:SetDegrees(-360)
  rotationAnim:SetDuration(1)

  spinnerAnimGroup:Play()

  -- Update spinner visibility.
  local UPDATE_INTERVAL = 0.2
  local timer = UPDATE_INTERVAL
  frame:HookScript("OnUpdate", function(_, elapsed)
    timer = timer + elapsed
    if timer >= UPDATE_INTERVAL then
      timer = 0
      if ListItemParser:IsParsing(options.list) then
        frame.spinnerButton:Show()
        frame.title:SetPoint("RIGHT", frame.spinnerButton, "LEFT", 0, 0)
      else
        frame.spinnerButton:Hide()
        frame.title:SetPoint("RIGHT", frame.transportButton, "LEFT", 0, 0)
      end
    end
  end)

  return frame
end
