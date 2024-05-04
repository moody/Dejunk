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

--- @class ListFrameIconButtonWidgetOptions : FrameWidgetOptions
--- @field texture string
--- @field textureSize number
--- @field onClick? fun(self: ListFrameIconButtonWidget, button: string)

-- =============================================================================
-- Widgets - List Frame
-- =============================================================================

--- Creates an ItemsFrame for displaying a List.
--- @param options ListFrameWidgetOptions
--- @return ListFrameWidget frame
function Widgets:ListFrame(options)
  local SearchData = {
    isSearching = false,
    searchText = ""
  }

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
    if SearchData.isSearching and SearchData.searchText ~= "" then
      return options.list:GetSearchItems(SearchData.searchText)
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
  frame.transportButton = self:ListFrameIconButton({
    name = "$parent_TransportButton",
    parent = frame.titleButton,
    points = { { "TOPRIGHT" }, { "BOTTOMRIGHT" } },
    texture = Addon:GetAsset("transport-icon"),
    textureSize = frame.title:GetStringHeight(),
    onClick = function() TransportFrame:Toggle(options.list) end,
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(L.TRANSPORT)
      tooltip:AddLine(L.LIST_FRAME_TRANSPORT_BUTTON_TOOLTIP)
    end
  })

  -- Search button OnClick handler.
  local function searchButton_onClick()
    SearchData.isSearching = not SearchData.isSearching
    if SearchData.isSearching then
      frame.searchBox:Show()
      frame.searchBox:SetText("")
      frame.searchBox:SetFocus()
      frame.searchButton.texture:SetTexture(Addon:GetAsset("x-icon"))
      frame.title:Hide()
    else
      frame.title:Show()
      frame.searchBox:Hide()
      frame.searchButton.texture:SetTexture(Addon:GetAsset("search-icon"))
    end
  end

  -- Search button.
  frame.searchButton = self:ListFrameIconButton({
    name = "$parent_SearchButton",
    parent = frame.titleButton,
    points = {
      { "TOPRIGHT",    frame.transportButton, "TOPLEFT",    0, 0 },
      { "BOTTOMRIGHT", frame.transportButton, "BOTTOMLEFT", 0, 0 }
    },
    texture = Addon:GetAsset("search-icon"),
    textureSize = frame.title:GetStringHeight(),
    onClick = searchButton_onClick,
    onUpdateTooltip = function(self, tooltip)
      tooltip:SetText(SearchData.isSearching and L.CLEAR_SEARCH or L.SEARCH)
    end
  })

  -- Search box.
  frame.searchBox = CreateFrame("EditBox", "$parent_SearchBox", frame.titleButton)
  frame.searchBox:SetFontObject("GameFontNormal")
  frame.searchBox:SetTextColor(1, 1, 1)
  frame.searchBox:SetAutoFocus(false)
  frame.searchBox:SetMultiLine(false)
  frame.searchBox:SetCountInvisibleLetters(true)
  frame.searchBox:SetPoint("TOPLEFT", Widgets:Padding(), 0)
  frame.searchBox:SetPoint("BOTTOMLEFT", Widgets:Padding(), 0)
  frame.searchBox:SetPoint("TOPRIGHT", frame.searchButton, "TOPLEFT", 0, 0)
  frame.searchBox:SetPoint("BOTTOMRIGHT", frame.searchButton, "BOTTOMLEFT", 0, 0)
  frame.searchBox:Hide()

  -- Search box placeholder text.
  frame.searchBox.placeholderText = frame.searchBox:CreateFontString(
    "$parent_PlaceholderText", "ARTWORK", "GameFontNormal")
  frame.searchBox.placeholderText:SetText(Colors.White(L.SEARCH))
  frame.searchBox.placeholderText:SetPoint("LEFT")
  frame.searchBox.placeholderText:SetPoint("RIGHT")
  frame.searchBox.placeholderText:SetJustifyH("LEFT")
  frame.searchBox.placeholderText:SetAlpha(0.5)

  frame.searchBox:SetScript("OnEscapePressed", function(self)
    searchButton_onClick()
  end)

  frame.searchBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  frame.searchBox:SetScript("OnTextChanged", function(self)
    SearchData.searchText = self:GetText()
    if SearchData.searchText == "" then
      self.placeholderText:Show()
    else
      self.placeholderText:Hide()
    end
  end)

  return frame
end

-- =============================================================================
-- Widgets - List Frame Icon Button
-- =============================================================================

--- Creates a button Frame with an icon.
--- @param options ListFrameIconButtonWidgetOptions
--- @return ListFrameIconButtonWidget frame
function Widgets:ListFrameIconButton(options)
  -- Defaults.
  options.frameType = "Button"

  -- Base frame.
  local frame = self:Frame(options) ---@class ListFrameIconButtonWidget : FrameWidget
  frame:SetBackdropColor(0, 0, 0, 0)
  frame:SetBackdropBorderColor(0, 0, 0, 0)
  frame:SetWidth(options.textureSize + self:Padding(4))

  -- Texture.
  frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
  frame.texture:SetTexture(options.texture)
  frame.texture:SetSize(options.textureSize, options.textureSize)
  frame.texture:SetPoint("CENTER")

  frame:HookScript("OnEnter", function(self) self:SetBackdropColor(Colors.Yellow:GetRGBA(0.75)) end)
  frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
  frame:SetScript("OnClick", options.onClick)

  return frame
end
