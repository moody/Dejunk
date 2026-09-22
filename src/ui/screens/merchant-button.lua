local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local ActionCreators = Addon:GetModule("ActionCreators")
local Colors = Addon:GetModule("Colors")
local Commands = Addon:GetModule("Commands")
local DefaultStates = Addon:GetModule("DefaultStates")
local JunkFilter = Addon:GetModule("JunkFilter")
local L = Addon:GetModule("Locale")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

local LABEL_TEXT_FORMAT = Colors.Grey("(%s/%s)"):format(Colors.White("%s"), Colors.Red("%s"))

-- ============================================================================
-- Initialize
-- ============================================================================

-- Merchant button.
local rootComponent = Addon.Waffle:Flex({
  width = 108,
  height = "AUTO",

  align = "CENTER",
  justify = "CENTER",
  padding = Widgets:Padding(0.25),

  frameFactory = function()
    --- @class MerchantButtonWidget : ButtonWidget
    local frame = Widgets:Button({
      name = ADDON_NAME .. "_MerchantButton",
      parent = _G.MerchantFrame,
      labelText = LABEL_TEXT_FORMAT:format(0, 0),
      labelColor = Colors.Blue,
      enableClickHandling = true,
      enableDragging = true,
      frameStrata = "HIGH",
      onUpdateTooltip = function(this, tooltip)
        tooltip:SetOwner(this, "ANCHOR_RIGHT")

        if IsAltKeyDown() then
          local item = JunkFilter:GetNextDestroyableJunkItem()
          if item then
            tooltip:SetBagItem(item.bag, item.slot)
            tooltip:AddLine(" ")
            tooltip:AddDoubleLine(L.RIGHT_CLICK, Colors.Red(L.DESTROY))
            tooltip:Show()
            return
          end
        end

        tooltip:AddDoubleLine(Colors.Blue(ADDON_NAME), Colors.Grey(Addon.VERSION))
        tooltip:AddLine(Addon:SubjectDescription(L.LEFT_CLICK, L.START_SELLING))
        tooltip:AddLine(Addon:SubjectDescription(L.RIGHT_CLICK, L.TOGGLE_JUNK_FRAME))
        tooltip:AddLine(Addon:SubjectDescription(Addon:Concat("+", L.ALT_KEY, L.RIGHT_CLICK), Colors.Red(L.DESTROY_NEXT_ITEM)))
        tooltip:Show()
      end
    })

    Widgets:ConfigureForPointSync({
      frame = frame,
      getPoint = function()
        local point = StateManager:GetGlobalState().points.merchantButton
        return (point.relativeTo ~= DefaultStates.Global.points.merchantButton.relativeTo) and
            DefaultStates.Global.points.merchantButton or
            point
      end,
      setPoint = function(point) StateManager:Dispatch(ActionCreators.Global.points.merchantButton.set(point)) end
    })

    -- Click handlers.
    frame:SetClickHandler("LeftButton", "NONE", Commands.sell)
    frame:SetClickHandler("RightButton", "NONE", Commands.junk)
    frame:SetClickHandler("RightButton", "SHIFT", function()
      StateManager:Dispatch(ActionCreators.Global.points.merchantButton.reset())
    end)
    frame:SetClickHandler("RightButton", "ALT", Commands.destroy)

    -- Scripts.
    frame:HookScript("OnUpdate", function()
      frame:SetEnabled(not Addon:IsBusy())
    end)
    frame:HookScript("OnDragStart", function()
      frame:GetScript("OnLeave")(frame)
    end)
    frame:HookScript("OnDragStop", function()
      if frame:IsMouseOver() then
        frame:GetScript("OnEnter")(frame)
      end
    end)

    return frame
  end
})

-- Icon texture.
local iconComponent = rootComponent:AddChild({
  width = 24,
  height = 24,
  shrink = 0,

  --- @param parent MerchantButtonWidget
  frameFactory = function(parent)
    local icon = parent:CreateTexture("$parent_Icon", "ARTWORK")
    icon:SetTexture(Addon:GetAsset("dejunk-icon"))
    return icon
  end
})

-- Label font string, sized to its own text.
local labelComponent = rootComponent:AddChild({
  width = "AUTO",
  height = "AUTO",

  --- @param parent MerchantButtonWidget
  frameFactory = function(parent)
    local label = parent.label
    label:ClearAllPoints()
    label:SetJustifyH("LEFT")
    return parent.label
  end,

  --- @param label FontString
  onMeasure = function(label)
    return label:GetStringWidth(), label:GetStringHeight()
  end
})

rootComponent:Layout()

-- ============================================================================
-- Ticker
-- ============================================================================

-- Update visibility and components.
TickerManager:NewTicker(1 / 30, function()
  local show = Addon:IsAtMerchant() and StateManager:GetGlobalState().merchantButton
  rootComponent:SetVisibility(show and "VISIBLE" or "GONE")

  if show then
    --- @type FontString
    local label = labelComponent:GetFrame()
    local numSellable, numDestroyable = JunkFilter:GetNumJunkItems()
    local text = LABEL_TEXT_FORMAT:format(numSellable, numDestroyable)

    -- Update label text and icon size, only when the text actually changes.
    if text ~= label:GetText() then
      label:SetTextToFit(text)
      -- Since label's word-wrap is disabled, GetStringHeight() will always be one line tall.
      local iconSize = math.floor(label:GetStringHeight() + Widgets:Padding(1.5) + 0.5)
      iconComponent:SetSize(iconSize, iconSize)
      rootComponent:MarkDirty()
    end
  end

  rootComponent:Layout()
end)
