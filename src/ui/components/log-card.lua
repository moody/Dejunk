local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class LogCardComponentOptions
--- @field getAccentColor fun(entry: LogEntry): Color Returns the color of the strip on the left edge.
--- @field getValueText fun(entry: LogEntry): string Returns the value at the right of the link.
--- @field getSubtext fun(entry: LogEntry): string Returns the small text at the left of the second line, with its own colors. Called again when the time changes.
--- @field getTimeText fun(entry: LogEntry): string Returns the small grey text at the right of the second line. Called again when the time changes.
--- @field onUpdateTooltip? fun(entry: LogEntry, tooltip: Tooltip) Shown while hovering the card.

-- =============================================================================
-- ComponentFactory - LogCard
-- =============================================================================

--- Creates a card for a log entry, with the item's icon and stack count, a link line (the link and the value),
--- a line of small text (the subtext and the time), and a strip on the left edge. Hidden until it has an entry.
--- @param options LogCardComponentOptions
--- @return LogCardComponent root
function ComponentFactory:LogCard(options)
  local frame ---@type FrameWidget?
  local accent ---@type Texture?
  local entry ---@type LogEntry?
  local accentColor = Colors.White

  --- The entry the card last showed. An entry never changes, so the same one needs no update.
  --- @type LogEntry?
  local shownEntry

  --- The `time()` when the card last set the subtext and time.
  --- @type integer?
  local shownTime

  --- Brightens the card while hovered, if it has an entry.
  local function refreshBackdrop()
    if not frame then return end

    local isHighlighted = entry and frame:GetEventValue("HOVERED")
    local level = isHighlighted and 0.14 or 0.1
    frame:SetBackdropColor(level, level, level, 1)
  end

  --- @class LogCardComponent : WaffleFlexComponent<FrameWidget>
  local root = Addon.Waffle:Flex({
    align = "CENTER",
    paddingLeft = ComponentFactory.CARD_ACCENT_WIDTH,
    visibility = "INVISIBLE",

    --- @param parent Frame
    frameFactory = function(parent)
      frame = Widgets:Frame({
        parent = parent,
        frameType = "Button",
        tooltipAnchor = "ANCHOR_LEFT",

        --- @param tooltip Tooltip
        onUpdateTooltip = function(_, tooltip)
          if entry and options.onUpdateTooltip then
            options.onUpdateTooltip(entry, tooltip)
          else
            tooltip:Hide()
          end
        end
      })
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:OnEvent("HOVERED", refreshBackdrop)
      refreshBackdrop()

      accent = frame:CreateTexture("$parent_Accent", "ARTWORK")
      accent:SetWidth(ComponentFactory.CARD_ACCENT_WIDTH)
      accent:SetPoint("TOPLEFT")
      accent:SetPoint("BOTTOMLEFT")
      accent:SetColorTexture(accentColor:GetRGB())

      return frame
    end
  })

  -- Content, beside the accent strip.
  local content = root:AddRow({
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(0.75),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding()
  })

  -- Icon.
  local icon = content:AttachComponent(ComponentFactory:ItemIcon({ size = 32 }))

  -- Text, beside the icon.
  local textColumn = content:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.5) })

  -- Link line: the link at the left, the value at the right.
  local linkLine = textColumn:AddRow({ height = "AUTO", align = "CENTER", gap = Widgets:Padding() })

  local linkLabel = linkLine:AttachComponent(ComponentFactory:Text({
    fontObject = B.FontObjects.Large,
    wordWrap = false,
    truncationTooltip = false
  }))

  local valueLabel = linkLine:AttachComponent(ComponentFactory:Text({
    width = "AUTO",
    justifyH = "RIGHT",
    wordWrap = false,
    truncationTooltip = false
  }))

  -- Second line: the subtext at the left, the time at the right.
  local detailLine = textColumn:AddRow({ height = "AUTO", align = "CENTER", gap = Widgets:Padding() })

  local subtextLabel = detailLine:AttachComponent(ComponentFactory:Text({
    fontObject = B.FontObjects.Small,
    wordWrap = false,
    truncationTooltip = false
  }))

  local timeLabel = detailLine:AttachComponent(ComponentFactory:Text({
    fontObject = B.FontObjects.Small,
    color = Colors.Grey,
    width = "AUTO",
    justifyH = "RIGHT",
    wordWrap = false,
    truncationTooltip = false
  }))

  --- Shows the entry, or hides the card if it has none.
  --- @param newEntry? LogEntry
  function root:SetEntry(newEntry)
    local hadEntry = entry ~= nil
    entry = newEntry

    if not newEntry then
      shownEntry = nil
      root:SetVisibility("INVISIBLE")
      return
    end

    root:SetVisibility("VISIBLE")

    -- A card under the mouse gets no new enter event, so refresh its highlight.
    if not hadEntry then refreshBackdrop() end

    -- The subtext and time depend on the current time, so they are set again when it changes.
    local now = time()
    if newEntry ~= shownEntry or now ~= shownTime then
      shownTime = now
      subtextLabel:SetText(options.getSubtext(newEntry))
      timeLabel:SetText(options.getTimeText(newEntry))
    end

    if newEntry == shownEntry then return end
    shownEntry = newEntry

    local item = newEntry.attempt.item
    icon:SetItem(item)
    linkLabel:SetText(item.link)
    valueLabel:SetText(options.getValueText(newEntry))

    accentColor = options.getAccentColor(newEntry)
    if accent then accent:SetColorTexture(accentColor:GetRGB()) end

    -- A card under the mouse gets no new enter event when its entry changes, so refresh its tooltip.
    if frame and frame:IsVisible() and frame:IsMouseOver() then frame:UpdateTooltip() end
  end

  return root
end
