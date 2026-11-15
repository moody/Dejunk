local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local Logger = Addon:GetModule("Logger")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindowLog
local MainWindowLog = Addon:GetModule("MainWindowLog")

--- The label and color of each outcome.
--- @type table<LogOutcome, { text: string, color: Color }>
local OutcomeStyles = {
  [Logger.Outcomes.SOLD] = { text = L.SOLD, color = Colors.Yellow },
  [Logger.Outcomes.DESTROYED] = { text = L.DESTROYED, color = Colors.Red },
  [Logger.Outcomes.FAILED_TO_SELL] = { text = L.FAILED_TO_SELL, color = Colors.Grey },
  [Logger.Outcomes.FAILED_TO_DESTROY] = { text = L.FAILED_TO_DESTROY, color = Colors.Grey },
  [Logger.Outcomes.MAY_NOT_HAVE_SOLD] = { text = L.MAY_NOT_HAVE_SOLD, color = Colors.Grey },
  [Logger.Outcomes.MAY_NOT_HAVE_DESTROYED] = { text = L.MAY_NOT_HAVE_DESTROYED, color = Colors.Grey }
}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the outcome in its color, followed by a colon and space.
--- @param entry LogEntry
--- @return string
local function getOutcomeText(entry)
  local style = OutcomeStyles[entry.outcome]
  return style.color(style.text) .. Colors.Grey(": ")
end

--- Returns the color of the entry's outcome.
--- @param entry LogEntry
--- @return Color
local function getAccentColor(entry)
  return OutcomeStyles[entry.outcome].color
end

--- Returns how long ago the outcome was reported.
--- @param entry LogEntry
--- @return string
local function getTimeText(entry)
  local seconds = math.max(time() - entry.time, 0)

  if seconds >= 3600 then
    return B.Strings.HOURS_ABBREVIATED_TEXT:format(math.floor(seconds / 3600))
  elseif seconds >= 60 then
    return B.Strings.MINUTES_ABBREVIATED_TEXT:format(math.floor(seconds / 60))
  end

  return B.Strings.SECONDS_ABBREVIATED_TEXT:format(seconds)
end

--- Returns the details of the entry, such as its reason and profile.
--- @param entry LogEntry
--- @return string
local function getSubtext(entry)
  local parts = {}

  if entry.attempt.type == "MANUAL" then parts[#parts + 1] = Colors.White(L.MANUAL) end

  local reason = entry.attempt.reason
  if reason then parts[#parts + 1] = Colors.Grey(L.REASON .. ": ") .. Colors:Strip(reason) end

  if entry.profileId ~= StateManager:GetProfileState().id then
    local profile = StateManager:GetProfileStateById(entry.profileId)
    if profile then parts[#parts + 1] = Colors.Grey(L.PROFILE .. ": ") .. profile.name end
  end

  return Addon:Concat(" · ", unpack(parts))
end

--- Returns the price of the item's whole stack as coins, or an empty string if the item has no value.
--- @param entry LogEntry
--- @return string
local function getValueText(entry)
  local item = entry.attempt.item

  if not (item.noValue or item.price == 0) then
    return B.Money:GetCoinText(item.price * item.quantity)
  end

  return ""
end

--- Fills the tooltip with the item.
--- @param entry LogEntry
--- @param tooltip Tooltip
local function updateTooltip(entry, tooltip)
  tooltip:SetHyperlink(entry.attempt.item.link)
end

-- ============================================================================
-- MainWindowLog
-- ============================================================================

--- Creates the panel of log entries.
--- @return TitledPanelComponent panel
function MainWindowLog:CreateLogPanel()
  local panel = ComponentFactory:TitledPanel({
    titleText = Colors.Blue(L.LOG),
    titleJustify = "LEFT"
  })
  panel.Content:SetGap(Widgets:Padding())

  panel.Content:AttachComponent(ComponentFactory:Text({
    text = L.LOG_DESCRIPTION,
    fontObject = B.FontObjects.Small,
    color = Colors.Grey,
    justifyH = "CENTER"
  }))
  panel.Content:AttachComponent(ComponentFactory:Divider())

  panel.Content:AttachComponent(ComponentFactory:CardList({
    cardCount = 10,
    emptyText = L.NO_LOG_ENTRIES,
    getEntries = function() return Logger:GetEntries() end,
    createCard = function()
      return ComponentFactory:LogCard({
        getOutcomeText = getOutcomeText,
        getAccentColor = getAccentColor,
        getValueText = getValueText,
        getSubtext = getSubtext,
        getTimeText = getTimeText,
        onUpdateTooltip = updateTooltip
      })
    end,
    setCard = function(card, entry)
      card:SetEntry(entry)
    end
  }))

  return panel
end
