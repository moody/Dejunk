local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Actions = Addon:GetModule("Actions")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class TransportFrame
local TransportFrame = Addon:GetModule("TransportFrame")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Sets the edit box text for the `frame` to comma-separated item IDs from the associated list.
--- @param frame TransportFrameWidget
local function export(frame)
  -- Set edit box text.
  local editBox = frame.textFrame.editBox
  local itemIds = frame.list:GetItemIds()
  editBox:SetText(table.concat(itemIds, ","))
  -- Select all.
  local numLetters = editBox:GetNumLetters()
  editBox:SetFocus()
  editBox:HighlightText(0, numLetters)
  editBox:SetCursorPosition(numLetters)
end

-- ============================================================================
-- TransportFrame
-- ============================================================================

--- Shows the frame for the given `list`.
--- @param list List
function TransportFrame:Show(list)
  self.frame.list = list
  self.frame:Show()
  export(self.frame)
end

--- Hides the frame.
function TransportFrame:Hide()
  self.frame:Hide()
end

--- Toggles the frame for the given `list`.
--- @param list List
function TransportFrame:Toggle(list)
  if list == self.frame.list and self.frame:IsShown() then
    self:Hide()
  else
    self:Show(list)
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

TransportFrame.frame = (function()
  --- @class TransportFrameWidget : WindowWidget
  --- @field list? List
  local frame = Widgets:Window({
    name = ADDON_NAME .. "_TransportFrame",
    width = 325,
    height = 375,
    enableClickHandling = true
  })

  frame:SetClickHandler("RightButton", "SHIFT", function()
    StateManager:Dispatch(Actions:ResetTransportFramePoint())
  end)

  Widgets:ConfigureForPointSync(frame, "TransportFrame")

  frame:HookScript("OnUpdate", function(self)
    if not self.list then return end
    self.title:SetText(Colors.Yellow("%s (%s)"):format(L.TRANSPORT, self.list.name))
  end)

  -- Import button.
  frame.importButton = Widgets:Button({
    name = "$parent_ImportButton",
    parent = frame,
    points = {
      { "BOTTOMLEFT", Widgets:Padding(), Widgets:Padding() },
      { "BOTTOMRIGHT", frame, "BOTTOM", -Widgets:Padding(0.25), Widgets:Padding() }
    },
    labelText = L.IMPORT,
    labelColor = Colors.Yellow,
    onClick = function(self)
      -- Import ids.
      local editBox = frame.textFrame.editBox
      for itemId in editBox:GetText():gmatch("%d+") do
        itemId = tonumber(itemId)
        if itemId and itemId > 0 and itemId <= 2147483647 then
          frame.list:Add(itemId, true)
        end
      end
      -- Clear.
      editBox:ClearFocus()
      editBox:HighlightText(0, 0)
    end
  })

  -- Export button.
  frame.exportButton = Widgets:Button({
    name = "$parent_ExportButton",
    parent = frame,
    points = {
      { "BOTTOMLEFT", frame, "BOTTOM", Widgets:Padding(0.25), Widgets:Padding() },
      { "BOTTOMRIGHT", -Widgets:Padding(), Widgets:Padding() }
    },
    labelText = L.EXPORT,
    labelColor = Colors.Yellow,
    onClick = function() export(frame) end
  })

  -- Text frame.
  frame.textFrame = Widgets:TextFrame({
    name = "$parent_TextFrame",
    parent = frame,
    points = {
      { "TOPLEFT", frame.titleButton, "BOTTOMLEFT", Widgets:Padding(), 0 },
      { "BOTTOMRIGHT", frame.exportButton, "TOPRIGHT", 0, Widgets:Padding(0.5) }
    },
    titleText = L.ITEM_IDS,
    descriptionText = L.TRANSPORT_FRAME_TOOLTIP
  })

  return frame
end)()
