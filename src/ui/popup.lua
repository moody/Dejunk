local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

--- @class Popup
local Popup = Addon:GetModule("Popup")

Popup.keys = {}

-- ============================================================================
-- Events
-- ============================================================================

local function handlePopup(popup)
  if popup and popup:IsShown() and Popup.keys[popup.which] then
    popup:Hide()
  end
end

EventManager:On(E.StateUpdated, function()
  if type(StaticPopup_ForEachShownDialog) == "function" then
    StaticPopup_ForEachShownDialog(handlePopup)
  else
    for i = 1, STATICPOPUP_NUMDIALOGS do
      local popup = _G["StaticPopup" .. i]
      handlePopup(popup)
    end
  end
end)

-- ============================================================================
-- Local Functions
-- ============================================================================

local function registerPopup(popupKey, popup)
  Popup.keys[popupKey] = true
  StaticPopupDialogs[popupKey] = popup
  return popupKey, popup
end

-- ============================================================================
-- Popup
-- ============================================================================

do -- Popup:GetInteger()
  local function toInt(value)
    local value = tonumber(value or "", 10)
    local isInt = type(value) == "number" and value == floor(value)
    return isInt and floor(value) or nil
  end

  local function getButton1(popup)
    if type(popup.GetButton1) == "function" then return popup:GetButton1() end
    return popup.button1
  end

  local function getEditBox(popup)
    if type(popup.GetEditBox) == "function" then return popup:GetEditBox() end
    return popup.editBox
  end

  local popupKey, popup = registerPopup("DEJUNK_GET_INTEGER_POPUP", {
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    hasEditBox = true,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnTextChanged = function(self)
      local isInt = toInt(self:GetText()) ~= nil
      getButton1(self:GetParent()):SetEnabled(isInt)
    end,
  })

  --[[
    Shows a popup requiring a valid integer input.

    options = {
      text? = string,
      initialValue? = string,
      onAccept? = function(self, value) -> nil,
      onCancel? = function(self) -> nil,
      onShow? = function(self) -> nil,
      onHide? = function(self) -> nil
    }
  ]]
  function Popup:GetInteger(options)
    popup.text = options.text

    popup.EditBoxOnEnterPressed = function(self)
      local parent = self:GetParent()
      if getButton1(parent):IsEnabled() then
        if options.onAccept then options.onAccept(self, toInt(self:GetText())) end
        parent:Hide()
      end
    end

    popup.OnAccept = function(self)
      if options.onAccept then
        options.onAccept(self, toInt(getEditBox(self):GetText()))
      end
    end
    popup.OnCancel = options.onCancel

    popup.OnShow = function(self)
      local editBox = getEditBox(self)
      editBox:SetText(tostring(options.initialValue or ""))
      editBox:HighlightText()
      editBox:SetCursorPosition(editBox:GetNumLetters())
      if options.onShow then options.onShow(self) end
    end
    popup.OnHide = options.onHide

    StaticPopup_Show(popupKey)
  end
end
