local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class TransportFrame
local TransportFrame = Addon:GetModule("TransportFrame")

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Always set before the frame is shown or either button is usable.
--- @type List
local currentList

--- Fills the edit box with the current list's item IDs and selects them.
local function export()
  local editBox = Components.TextFrame:GetFrame().editBox
  editBox:SetText(table.concat(currentList:GetItemIds(), ","))

  local numLetters = editBox:GetNumLetters()
  editBox:SetFocus()
  editBox:HighlightText(0, numLetters)
  editBox:SetCursorPosition(numLetters)
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "TransportFrame",
  width = 325,
  height = 375,
  titleText = Colors.Yellow(L.TRANSPORT),
  getPoint = function() return StateManager:GetGlobalState().points.transportFrame end,
  setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.transportFrame.set(point)) end,
  onResetPoint = function() StateManager:Dispatch(ActionCreators.Global.points.transportFrame.reset()) end
})

-- ============================================================================
-- Content Components
-- ============================================================================

Components.Content = Components.Root:AddChild({
  direction = "COLUMN",
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
})

Components.TextFrame = Components.Content:AddChild({
  frameFactory = function()
    return Widgets:TextFrame({
      name = "$parent_TextFrame",
      titleText = L.ITEM_IDS,
      descriptionText = L.TRANSPORT_FRAME_TOOLTIP
    })
  end
})

Components.ButtonRow = Components.Content:AddRow({
  maxHeight = 30,
  gap = Widgets:Padding(0.5)
})

Components.ImportButton = Components.ButtonRow:AddChild({
  frameFactory = function(parent)
    return Widgets:Button({
      name = "$parent_ImportButton",
      labelText = L.IMPORT,
      labelColor = Colors.Yellow,
      onClick = function()
        local editBox = Components.TextFrame:GetFrame().editBox
        for itemId in editBox:GetText():gmatch("%d+") do
          itemId = tonumber(itemId)
          if itemId and itemId > 0 and itemId <= 2147483647 then
            currentList:Add(itemId, true)
          end
        end
        editBox:ClearFocus()
        editBox:HighlightText(0, 0)
      end
    })
  end
})

Components.ExportButton = Components.ButtonRow:AddChild({
  frameFactory = function(parent)
    return Widgets:Button({
      name = "$parent_ExportButton",
      labelText = L.EXPORT,
      labelColor = Colors.Yellow,
      onClick = export
    })
  end
})

-- ============================================================================
-- TransportFrame
-- ============================================================================

--- Shows the frame for the given `list`.
--- @param list List
function TransportFrame:Show(list)
  currentList = list
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
  Components.Root.TitleText:GetFrame():SetText(list.name)
  export()
end

--- Hides the frame.
function TransportFrame:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

--- Toggles the frame for the given `list`.
--- @param list List
function TransportFrame:Toggle(list)
  if list == currentList and Components.Root:GetVisibility() ~= "GONE" then
    self:Hide()
  else
    self:Show(list)
  end
end
