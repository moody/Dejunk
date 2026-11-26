local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Items = Addon:GetModule("Items")
local L = Addon:GetModule("Locale")
local Logger = Addon:GetModule("Logger")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class MainWindowLog
local MainWindowLog = Addon:GetModule("MainWindowLog")

local MANUAL_OUTCOME_FORMAT = "%s " .. Colors.Grey("(%s)"):format(Colors.White(L.MANUAL))
local REASON_TEXT_FORMAT = Colors.Grey(L.REASON .. ": ") .. "%s"
local PROFILE_TEXT_FORMAT = Colors.Grey(L.PROFILE .. ": ") .. "%s"

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

--- @class LogFilter
--- @field text string
--- @field outcomes? table<LogOutcome, boolean> The outcomes shown. Every outcome if `nil`.

--- The filters, in the order they are shown. The first shows every outcome.
--- @type LogFilter[]
local Filters = {
  { text = L.ALL },
  {
    text = L.SELLING,
    outcomes = {
      [Logger.Outcomes.SOLD] = true,
      [Logger.Outcomes.FAILED_TO_SELL] = true,
      [Logger.Outcomes.MAY_NOT_HAVE_SOLD] = true
    }
  },
  {
    text = L.DESTROYING,
    outcomes = {
      [Logger.Outcomes.DESTROYED] = true,
      [Logger.Outcomes.FAILED_TO_DESTROY] = true,
      [Logger.Outcomes.MAY_NOT_HAVE_DESTROYED] = true
    }
  }
}

--- The filter the list shows.
--- @type LogFilter
local selectedFilter = Filters[1]

--- The entries that match `selectedFilter`, newest first. Not used while it shows every outcome.
--- @type LogEntry[]
local filteredEntries = {}

--- Whether `filteredEntries` is out of date.
local isFilteredStale = true

-- ============================================================================
-- Events
-- ============================================================================

EventManager:On(E.ItemLogged, function()
  isFilteredStale = true
end)

-- ============================================================================
-- Local Functions
-- ============================================================================

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

--- Returns the details of the entry, such as its outcome, reason, and profile.
--- @param entry LogEntry
--- @return string
local function getSubtext(entry)
  local style = OutcomeStyles[entry.outcome]
  local outcomeText = style.color(style.text)

  if entry.attempt.type == "MANUAL" then outcomeText = MANUAL_OUTCOME_FORMAT:format(outcomeText) end

  local parts = { outcomeText }

  local reason = entry.attempt.reason
  if reason then parts[#parts + 1] = REASON_TEXT_FORMAT:format(Colors:Strip(reason)) end

  if entry.profileId ~= StateManager:GetProfileState().id then
    local profile = StateManager:GetProfileStateById(entry.profileId)
    if profile then parts[#parts + 1] = PROFILE_TEXT_FORMAT:format(profile.name) end
  end

  return Addon:Concat(" · ", unpack(parts))
end

--- Returns the price of the item's whole stack as coins, or an empty string if the item has no value.
--- @param entry LogEntry
--- @return string
local function getValueText(entry)
  local price = Items:GetStackPrice(entry.attempt.item)
  if price > 0 then return B.Money:GetCoinText(price) end

  return ""
end

--- Returns the entries that match the selected filter.
--- @return LogEntry[]
local function getEntries()
  if selectedFilter.outcomes then
    if isFilteredStale then
      isFilteredStale = false

      local count = 0
      for _, entry in ipairs(Logger:GetEntries()) do
        if selectedFilter.outcomes[entry.outcome] then
          count = count + 1
          filteredEntries[count] = entry
        end
      end

      for i = #filteredEntries, count + 1, -1 do filteredEntries[i] = nil end
    end

    return filteredEntries
  end

  return Logger:GetEntries()
end

--- Returns the text shown while the list is empty.
--- @return string
local function getEmptyText()
  if selectedFilter.outcomes then
    return L.NO_MATCHING_LOG_ENTRIES
  end

  return L.NO_LOG_ENTRIES
end

--- Returns the totals of this session.
--- @return string
local function getTotalsText()
  local totals = Logger:GetTotals()

  return Addon:Concat(
    " · ",
    Colors.Grey(L.ITEMS_SOLD:format(Colors.White(totals.numSold))),
    Colors.Grey(L.PROFIT:format(Colors.White(B.Money:GetCoinText(totals.profit)))),
    Colors.Grey(L.ITEMS_DESTROYED:format(Colors.White(totals.numDestroyed)))
  )
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

  -- Filter tabs, with no gap so their underlines form one line.
  local filterRow = panel.Content:AddRow({ height = "AUTO" })

  --- @type table<LogFilter, TabComponent>
  local filterTabs = {}

  for _, filter in ipairs(Filters) do
    filterTabs[filter] = filterRow:AttachComponent(ComponentFactory:Tab({
      labelText = filter.text,
      onClick = function()
        filterTabs[selectedFilter]:SetSelected(false)
        selectedFilter = filter
        isFilteredStale = true
        filterTabs[filter]:SetSelected(true)
      end
    }))
  end

  filterTabs[selectedFilter]:SetSelected(true)

  panel.Content:AttachComponent(ComponentFactory:CardList({
    cardCount = 10,
    emptyText = getEmptyText,
    getEntries = getEntries,
    createCard = function()
      return ComponentFactory:LogCard({
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

  local totalsLabel = panel:AddFooter({
    text = getTotalsText(),
    fontObject = B.FontObjects.Small
  })

  EventManager:On(E.ItemLogged, function() totalsLabel:SetText(getTotalsText()) end)

  return panel
end
