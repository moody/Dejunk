local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local ListItemParser = Addon:GetModule("ListItemParser")
local TickerManager = Addon:GetModule("TickerManager")
local TransportFrame = Addon:GetModule("TransportFrame")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ListPanelComponentOptions
--- @field list List
--- @field getSearchText fun(): string Returns the text the list is filtered by. Shows every item when empty.
--- @field cardCount integer Number of items shown at once.
--- @field iconSize? integer Defaults to the `ItemCard` default.
--- @field fontObject? Font Defaults to the `ItemCard` default.

-- =============================================================================
-- ComponentFactory - ListPanel
-- =============================================================================

--- Creates a titled panel for a `List`, with import/export buttons in its title bar.
--- @param options ListPanelComponentOptions
--- @return ListPanelComponent root
function ComponentFactory:ListPanel(options)
  local list = options.list

  --- @class ListPanelComponent : TitledPanelComponent
  local root = ComponentFactory:TitledPanel({
    titleText = Colors.White(list.name),
    titleJustify = "LEFT",

    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(list.name)
      tooltip:AddLine(list.description)
      tooltip:AddLine(" ")
      tooltip:AddLine(L.LIST_FRAME_TOOLTIP)
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(
        Addon:Concat("+", B.Strings.CTRL_KEY_TEXT, B.Strings.ALT_KEY_TEXT, L.RIGHT_CLICK),
        L.REMOVE_ALL_ITEMS
      )
    end,

    onClick = function(button)
      if button == "RightButton" and IsControlKeyDown() and IsAltKeyDown() then list:RemoveAll() end
    end
  })

  -- Fixed height, since the buttons have no height of their own to size an `"AUTO"` bar by.
  local _, fontHeight = B.FontObjects.Normal:GetFont()
  root.TitleBar:SetHeight(fontHeight + Widgets:Padding(2))

  -- Spinner, shown while the list is loading.
  local spinner = root.TitleBar:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("spinner-icon"),
    highlightColor = Colors.Blue,
    onClick = function() end,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(("%s: %s%%"):format(L.LOADING, Colors.Blue(list:GetParsedItemPercentage())))
    end
  }))
  spinner:SetVisibility("GONE")

  spinner:WhenFrameReady(function(button)
    local animationGroup = button.icon:CreateAnimationGroup()
    animationGroup:SetLooping("REPEAT")

    local rotation = animationGroup:CreateAnimation("Rotation")
    rotation:SetDegrees(-360)
    rotation:SetDuration(1)

    animationGroup:Play()
  end)

  -- Import/export button.
  root.TitleBar:AttachComponent(ComponentFactory:IconButton({
    icon = Addon:GetAsset("transport-icon"),
    highlightColor = Colors.Yellow,
    onClick = function() TransportFrame:Toggle(list) end,
    onUpdateTooltip = function(_, tooltip)
      tooltip:SetText(L.TRANSPORT)
      tooltip:AddLine(L.LIST_FRAME_TRANSPORT_BUTTON_TOOLTIP)
    end
  }))

  root.Content:AttachComponent(ComponentFactory:ItemList({
    cardCount = options.cardCount,
    iconSize = options.iconSize,
    fontObject = options.fontObject,

    getItems = function()
      local searchText = options.getSearchText()
      if searchText ~= "" then return list:GetSearchItems(searchText) end
      return list:GetItems()
    end,

    addItem = function(itemId)
      list:Add(itemId)
    end,

    onUpdateItemTooltip = function(item, tooltip)
      tooltip:SetHyperlink(item.link)
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.RIGHT_CLICK, L.REMOVE)
      tooltip:AddDoubleLine(
        Addon:Concat("+", B.Strings.SHIFT_KEY_TEXT, L.RIGHT_CLICK),
        L.ADD_TO_LIST:format(list:GetOpposite().name)
      )
      tooltip:AddDoubleLine(
        Addon:Concat("+", B.Strings.CTRL_KEY_TEXT, L.RIGHT_CLICK),
        L.ADD_TO_LIST:format(list:GetSibling():GetOpposite().name)
      )
      tooltip:AddDoubleLine(
        Addon:Concat("+", B.Strings.ALT_KEY_TEXT, L.RIGHT_CLICK),
        L.ADD_TO_LIST:format(list:GetSibling().name)
      )
    end,

    onItemClick = function(item, button)
      if button == "RightButton" then
        if IsShiftKeyDown() then
          list:GetOpposite():Add(item.id)
        elseif IsControlKeyDown() then
          list:GetSibling():GetOpposite():Add(item.id)
        elseif IsAltKeyDown() then
          list:GetSibling():Add(item.id)
        else
          list:Remove(item.id)
        end
      end
    end
  }))

  -- Shows or hides the spinner as the list loads.
  root:WhenFrameReady(function(frame)
    local wasParsing = false

    TickerManager:NewTicker(0.2, function()
      local isParsing = ListItemParser:IsParsing(list)
      if isParsing == wasParsing then return end

      wasParsing = isParsing
      spinner:SetVisibility(isParsing and "VISIBLE" or "GONE")
      root:Layout()
    end):BindFrame(frame)
  end)

  return root
end
