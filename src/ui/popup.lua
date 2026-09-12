local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

--- @class Popup
local Popup = Addon:GetModule("Popup")

Popup.keys = {}

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class PopupConfirmOptions
--- @field text? string
--- @field onAccept? fun(self: table)
--- @field onCancel? fun(self: table)
--- @field onShow? fun(self: table)
--- @field onHide? fun(self: table)

--- @class PopupGetIntegerOptions : PopupConfirmOptions
--- @field initialValue? string | number
--- @field onAccept? fun(self: table, value: integer)

--- @class PopupGetStringOptions : PopupConfirmOptions
--- @field initialValue? string
--- @field onAccept? fun(self: table, value: string)

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

local function getButton1(popup)
  if type(popup.GetButton1) == "function" then return popup:GetButton1() end
  return popup.button1
end

local function getEditBox(popup)
  if type(popup.GetEditBox) == "function" then return popup:GetEditBox() end
  return popup.editBox
end

--- Registers a single-edit-box popup and returns a `show(options)` function
--- that wires it up. `parse(text)` both validates the edit box's text (`nil`
--- means invalid, disabling button1) and transforms it into the value handed
--- to `options.onAccept`.
--- @param popupKey string
--- @param parse fun(text: string): any
--- @return fun(options: table)
local function newTextInputPopup(popupKey, parse)
  local popupKey, popup = registerPopup(popupKey, {
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    hasEditBox = true,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnTextChanged = function(self)
      getButton1(self:GetParent()):SetEnabled(parse(self:GetText()) ~= nil)
    end,
  })

  return function(options)
    popup.text = options.text

    popup.EditBoxOnEnterPressed = function(self)
      local parent = self:GetParent()
      if getButton1(parent):IsEnabled() then
        if options.onAccept then options.onAccept(self, parse(self:GetText())) end
        parent:Hide()
      end
    end

    popup.OnAccept = function(self)
      if options.onAccept then
        options.onAccept(self, parse(getEditBox(self):GetText()))
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

-- ============================================================================
-- Popup
-- ============================================================================

-- Popup:Confirm()
do
  local popupKey, popup = registerPopup("DEJUNK_CONFIRM_POPUP", {
    button1 = ACCEPT,
    button2 = CANCEL,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
  })

  --- Shows a plain yes/no confirmation popup.
  --- @param options PopupConfirmOptions
  function Popup:Confirm(options)
    popup.text = options.text
    popup.OnAccept = options.onAccept
    popup.OnCancel = options.onCancel
    popup.OnShow = options.onShow
    popup.OnHide = options.onHide

    StaticPopup_Show(popupKey)
  end
end

-- Popup:GetInteger()
do
  local show = newTextInputPopup("DEJUNK_GET_INTEGER_POPUP", function(value)
    local value = tonumber(value or "", 10)
    local isInt = type(value) == "number" and value == floor(value)
    return isInt and floor(value) or nil
  end)

  --- Shows a popup requiring a valid integer input.
  --- @param options PopupGetIntegerOptions
  function Popup:GetInteger(options)
    show(options)
  end
end

-- Popup:GetString()
do
  local show = newTextInputPopup("DEJUNK_GET_STRING_POPUP", function(value)
    value = (value or ""):trim()
    if value == "" then return nil end
    return value
  end)

  --- Shows a popup requiring a non-empty text input.
  --- @param options PopupGetStringOptions
  function Popup:GetString(options)
    show(options)
  end
end
