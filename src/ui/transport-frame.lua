local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
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

Components.Root = Addon.Waffle:Flex({
  width = 325,
  height = 375,
  direction = "COLUMN",
  hidden = true,

  defaultFrameFactory = function(parent)
    return CreateFrame("Frame")
  end,

  frameFactory = function(parent)
    local frame = Widgets:Frame({
      name = ADDON_NAME .. "_TransportFrame",
      enableClickHandling = true,
      enableDragging = true
    })
    frame:SetFrameLevel(10)

    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.transportFrame.reset())
    end)

    Widgets:ConfigureForPointSync(frame, "TransportFrame")

    table.insert(UISpecialFrames, frame:GetName())

    frame:Hide()
    return frame
  end
})

-- ============================================================================
-- Title Components
-- ============================================================================

Components.TitleRow = Components.Root:AddRow({
  height = 32,
  paddingLeft = Widgets:Padding(),
  frameFactory = function(parent)
    local frame = Widgets:Frame({ parent = parent })
    frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
    return frame
  end
})

Components.TitleText = Components.TitleRow:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Yellow(L.TRANSPORT))
    return fontString
  end
})

Components.CloseButton = Components.TitleRow:AddChild({
  width = 46,
  frameFactory = function(parent)
    return Widgets:TitleFrameIconButton({
      name = "$parent_CloseButton",
      texture = Addon:GetAsset("x-icon"),
      textureSize = 14,
      highlightColor = Colors.Red,
      onClick = function() TransportFrame:Hide() end
    })
  end
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
  Components.Root:SetHidden(false)
  Components.Root:Layout()
  Components.TitleText:GetFrame():SetText(list.name)
  export()
end

--- Hides the frame.
function TransportFrame:Hide()
  Components.Root:SetHidden(true)
  Components.Root:Layout()
end

--- Toggles the frame for the given `list`.
--- @param list List
function TransportFrame:Toggle(list)
  if list == currentList and not Components.Root:GetHidden() then
    self:Hide()
  else
    self:Show(list)
  end
end
