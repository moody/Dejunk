local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class CardListComponentOptions<Entry, Card>
--- @field cardCount integer Number of cards shown at once. The rest are reached by scrolling.
--- @field getEntries fun(): Entry[] Returns what to list, in order.
--- @field createCard fun(): Card Creates one card.
--- @field setCard fun(card: Card, entry: Entry?) Shows an entry on a card. `entry` is `nil` for a card with nothing to show.
--- @field emptyText? string Shown while there are no entries. Defaults to `L.NO_ITEMS`.
--- @field onMouseDown? fun() Called when the list is clicked outside of a card.

-- =============================================================================
-- ComponentFactory - CardList
-- =============================================================================

--- Creates a scrollable list with a fixed number of cards, whatever the number of entries.
--- @generic Entry, Card : WaffleFlexComponent
--- @param options CardListComponentOptions<Entry, Card>
--- @return CardListComponent root
function ComponentFactory:CardList(options)
  local slider = Widgets:Slider({ orientation = "VERTICAL" })
  slider:Hide()

  --- Shown in the middle of the list while it has no entries.
  --- @type FontString
  local emptyText

  --- Cards, from the top.
  --- @type WaffleFlexComponent[]
  local cards = {}

  --- @class CardListComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    gap = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, backdrop = false })
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        slider:SetValue(slider:GetValue() - delta)
      end)
      if options.onMouseDown then frame:SetScript("OnMouseDown", options.onMouseDown) end

      emptyText = frame:CreateFontString("$parent_EmptyText", "ARTWORK", B.FontObjects.Normal:GetName())
      emptyText:SetPoint("CENTER")
      emptyText:SetTextColor(Colors.Grey:GetRGB())
      emptyText:SetText(options.emptyText or L.NO_ITEMS)

      return frame
    end
  })

  -- Cards.
  local cardColumn = root:AddColumn({ gap = Widgets:Padding(0.5) })
  -- Slider, shown only while the list can scroll.
  local sliderColumn = root:AddColumn({ frame = slider, width = 12, visibility = "GONE" })

  for i = 1, options.cardCount do
    cards[i] = cardColumn:AttachComponent(options.createCard())
  end

  --- Shows the entries from the scrolled position on the cards, and sizes the slider to the list.
  local function refresh()
    local entries = options.getEntries()
    local count = #entries
    emptyText:SetShown(count == 0)

    local maxOffset = math.max(count - options.cardCount, 0)
    local _, sliderMax = slider:GetMinMaxValues()
    if sliderMax ~= maxOffset then slider:SetMinMaxValues(0, maxOffset) end

    local isScrollable = maxOffset > 0
    if isScrollable ~= sliderColumn:IsVisible() then
      sliderColumn:SetVisibility(isScrollable and "VISIBLE" or "GONE")
      if isScrollable then
        -- Re-show the slider a frame later, or its thumb stays invisible.
        TickerManager:After(0, function()
          if not slider:IsShown() then return end
          slider:Hide()
          slider:Show()
        end)
      end
    end

    local offset = math.floor(slider:GetValue() + 0.5)
    for i, card in ipairs(cards) do
      options.setCard(card, entries[i + offset])
    end

    root:Layout()
  end

  slider:SetScript("OnValueChanged", refresh)

  root:WhenFrameReady(function(frame)
    frame:HookScript("OnShow", refresh)
    TickerManager:NewTicker(1 / 30, refresh):BindFrame(frame)
  end)

  return root
end
