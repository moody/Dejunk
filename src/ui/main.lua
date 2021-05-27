local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Colors = Addon.Colors
local Commands = Addon.Commands
local Core = Addon.Core
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local E = Addon.Events
local EventManager = Addon.EventManager
local ItemFrames = Addon.ItemFrames
local L = Addon.Libs.L
local pairs = pairs
local UI = Addon.UI
local Widgets = Addon.UI.Widgets

-- ============================================================================
-- Local Functions
-- ============================================================================

local function getStatusText()
  local isBusy, reason = Core:IsBusy()
  if isBusy then return reason end

  if DB.GetProfileKey then
    return ("%s: |cFFFFFFFF%s|r"):format(
      L.ACTIVE_PROFILE_TEXT,
      DB:GetProfileKey()
    )
  end

  return ""
end

-- ============================================================================
-- Functions
-- ============================================================================

function UI:IsShown()
  return self.frame and self.frame:IsShown()
end

function UI:Toggle()
  if self:IsShown() then
    self:Hide()
  else
    self:Show()
  end
end

function UI:Show()
  if not self.frame then self:Create() end
  ItemFrames:HideAll()
  self.frame:Show()
end

function UI:Hide()
  if not self.frame then return end
  self.frame:Hide()
end

function UI:OnUpdate(elapsed)
  if not self.frame or not self.frame:IsShown() then return end

  -- Update status text.
  self.frame:SetStatusText(getStatusText())

  -- Update disabled state
  local disabled = Core:IsBusy()
  if self.disabled == disabled then return end
  self.disabled = disabled

  -- "Disable" widgets by showing or hiding them
  local func = disabled and "Hide" or "Show"
  for widget in pairs(self.widgetsToDisable) do
    widget.frame[func](widget.frame)
  end
end

function UI:Create()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(AddonName)
  frame:SetWidth(858)
  frame:SetHeight(660)
  frame.frame:SetMinResize(600, 500)
  frame:SetLayout("Flow")
  frame:SetCallback("OnClose", function()
    EventManager:Fire(E.MainUIClosed)
    ItemFrames:ReshowHidden()
  end)
  self.frame = frame
  self.widgetsToDisable = {}
  self.disabled = false

  -- Heading
  Widgets:Heading(
    frame,
    ("%s: %s"):format(
      L.VERSION_TEXT,
      DCL:ColorString(Addon.VERSION, Colors.Primary)
    )
  )

  -- Key Bindings button
  local keyBindings = Widgets:Button({
    parent = frame,
    text = _G.KEY_BINDINGS,
    width = 175,
    onClick = function()
      UI:Hide()

      _G.KeyBindingFrame_LoadUI()
      _G.KeyBindingFrame:Show()

      -- Navigate to "Dejunk" category
      for _, button in ipairs(_G.KeyBindingFrame.categoryList.buttons) do
        local name = button.element and button.element.name
        -- `string.find` because the text contains color
        if name and name:find(AddonName, 1, true) then
          button:Click()
          return
        end
      end
    end
  })
  self.widgetsToDisable[keyBindings] = true

  -- Toggle sell frame button.
  self.widgetsToDisable[Widgets:Button({
    parent = frame,
    text = L.TOGGLE_SELL_FRAME,
    onClick = function() Commands.sell() end
  })] = true

  -- Toggle destroy frame button.
  self.widgetsToDisable[Widgets:Button({
    parent = frame,
    text = L.TOGGLE_DESTROY_FRAME,
    onClick = function() Commands.destroy() end
  })] = true

  -- Container for the TreeGroup
  local treeGroupContainer = Widgets:SimpleGroup({
    parent = frame,
    fullWidth = true,
    fullHeight = true,
    layout = "Fill"
  })
  self.widgetsToDisable[treeGroupContainer] = true

  -- Set up groups
  local treeGroup =  AceGUI:Create("TreeGroup")
  treeGroup:SetLayout("Fill")
  treeGroup:EnableButtonTooltips(false)
  treeGroup:SetTree({
    { text = L.GENERAL_TEXT, value = "General" },
    { text = "", value = "SPACE_1", disabled = true },
    { text = L.SELL_TEXT, value = "Sell" },
    {
      text = DCL:ColorString(L.INCLUSIONS_TEXT, Colors.Red),
      value = "SellInclusions"
    },
    {
      text = DCL:ColorString(L.EXCLUSIONS_TEXT, Colors.Green),
      value = "SellExclusions"
    },
    { text = "", value = "SPACE_2", disabled = true },
    { text = L.DESTROY_TEXT, value = "Destroy" },
    {
      text = DCL:ColorString(L.INCLUSIONS_TEXT, Colors.Red),
      value = "DestroyInclusions"
    },
    {
      text = DCL:ColorString(L.EXCLUSIONS_TEXT, Colors.Green),
      value = "DestroyExclusions"
    },
    { text = "", value = "SPACE_3", disabled = true },
    { text = L.COMMANDS_TEXT, value = "Commands" },
    { text = "", value = "SPACE_4", disabled = true },
    { text = L.PROFILES_TEXT, value = "Profiles" }
  })

  treeGroup:SetCallback("OnGroupSelected", function(this, event, key)
    this:ReleaseChildren()

    local group = UI.Groups[key] or error(key .. " group not supported")
    local parent = AceGUI:Create(group.parent or "ScrollFrame")
    parent:SetLayout(group.layout or "Flow")
    parent:PauseLayout()

    group:Create(parent)

    parent:ResumeLayout()
    parent:DoLayout()

    this:AddChild(parent)
  end)

  treeGroup:SelectByValue("General")
  treeGroupContainer:AddChild(treeGroup)

  -- This function should only be called once
  self.Create = nil
end

do -- Hook "CloseSpecialWindows" to hide UI when Esc is pressed
  local closeSpecialWindows = _G.CloseSpecialWindows
  _G.CloseSpecialWindows = function()
    local found = closeSpecialWindows()

    if UI:IsShown() then
      UI:Hide()
      return true
    end

    return found
  end
end
