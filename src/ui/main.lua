local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Colors = Addon.Colors
local Confirmer = Addon.Confirmer
local Core = Addon.Core
local DCL = Addon.Libs.DCL
local Dejunker = Addon.Dejunker
local Destroyer = Addon.Destroyer
local L = Addon.Libs.L
local ListManager = Addon.ListManager
local pairs = pairs
local Tools = Addon.Tools
local UI = Addon.UI
local Utils = Addon.UI.Utils

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
  self.frame:Show()
end

function UI:Hide()
  if not self.frame then return end
  self.frame:Hide()
end

function UI:OnUpdate(elapsed)
  if not self.frame or not self.frame:IsShown() then return end

  -- Update status text
  self.frame:SetStatusText(
    (Dejunker:IsDejunking() and L.STATUS_SELLING_ITEMS_TEXT) or
    (Destroyer:IsDestroying() and L.STATUS_DESTROYING_ITEMS_TEXT) or
    (Confirmer:IsConfirming() and L.STATUS_CONFIRMING_ITEMS_TEXT) or
    (ListManager:IsParsing() and L.STATUS_UPDATING_LISTS_TEXT) or
    ""
  )

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
  frame:SetCallback("OnClose", Destroyer.StartAutoDestroy)
  self.frame = frame
  self.widgetsToDisable = {}
  self.disabled = false

  -- Heading
  Utils:Heading(
    frame,
    ("%s: %s"):format(
      L.VERSION_TEXT,
      DCL:ColorString(
        _G.GetAddOnMetadata(AddonName, "Version"),
        Colors.Primary
      )
    )
  )

  -- Start Destroying button
  local startDestroying = Utils:Button({
    parent = frame,
    text = L.START_DESTROYING_BUTTON_TEXT,
    width = 175,
    onClick = function() Destroyer:StartDestroying() end
  })
  self.widgetsToDisable[startDestroying] = true

  -- Key Bindings button
  local keyBindings = Utils:Button({
    parent = frame,
    text = _G.KEY_BINDINGS,
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

  -- Container for the TreeGroup
  local treeGroupContainer = Utils:SimpleGroup({
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
    { text = L.SELL_TEXT, value = "Sell" },
    { text = L.IGNORE_TEXT, value = "Ignore" },
    { text = L.DESTROY_TEXT, value = "Destroy" },
    { text = "", value = "Space1", disabled = true },
    { text = Tools:GetInclusionsString(), value = "Inclusions" },
    { text = Tools:GetExclusionsString(), value = "Exclusions" },
    { text = Tools:GetDestroyablesString(), value = "Destroyables" },
    { text = "", value = "Space2", disabled = true },
    { text = L.PROFILES_TEXT, value = "Profiles" }
  })

  treeGroup:SetCallback("OnGroupSelected", function(self, event, key)
    self:ReleaseChildren()

    local group = UI.Groups[key] or error(key .. " group not supported")
    local parent = AceGUI:Create(group.parent or "ScrollFrame")
    parent:SetLayout(group.layout or "Flow")
    parent:PauseLayout()

    group:Create(parent)

    parent:ResumeLayout()
    parent:DoLayout()

    self:AddChild(parent)
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
