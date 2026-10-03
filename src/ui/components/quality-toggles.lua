local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

local QUALITIES = {
  { key = "poor", text = L.POOR, color = Colors.QualityPoor },
  { key = "common", text = L.COMMON, color = Colors.QualityCommon },
  { key = "uncommon", text = L.UNCOMMON, color = Colors.QualityUncommon },
  { key = "rare", text = L.RARE, color = Colors.QualityRare },
  { key = "epic", text = L.EPIC, color = Colors.QualityEpic }
}

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class QualityTogglesComponentOptions
--- @field get fun(quality: ItemQualityKey): boolean Returns whether `quality` is selected.
--- @field set fun(quality: ItemQualityKey, value: boolean) Called with the new value when a quality is clicked.

-- =============================================================================
-- ComponentFactory - QualityToggles
-- =============================================================================

--- Creates a dark strip with a `CheckChip` per item quality, colored to match.
--- @param options QualityTogglesComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:QualityToggles(options)
  local root = Addon.Waffle:Flex({
    height = "AUTO",
    justify = "SPACE_BETWEEN",
    gap = Widgets:Padding(0.5),

    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.Black:GetRGBA(0.35))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end
  })

  for _, quality in ipairs(QUALITIES) do
    root:AttachComponent(ComponentFactory:CheckChip({
      text = quality.text,
      color = quality.color,
      get = function() return options.get(quality.key) end,
      set = function(value) options.set(quality.key, value) end
    }))
  end

  return root
end
