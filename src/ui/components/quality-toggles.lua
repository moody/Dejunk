local Addon = select(2, ...) ---@type Addon
local B = Addon:GetModule("Blizzard")
local Colors = Addon:GetModule("Colors")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

local QUALITIES = {
  { key = "poor", text = B.Strings.POOR_TEXT, color = Colors.QualityPoor },
  { key = "common", text = B.Strings.COMMON_TEXT, color = Colors.QualityCommon },
  { key = "uncommon", text = B.Strings.UNCOMMON_TEXT, color = Colors.QualityUncommon },
  { key = "rare", text = B.Strings.RARE_TEXT, color = Colors.QualityRare },
  { key = "epic", text = B.Strings.EPIC_TEXT, color = Colors.QualityEpic }
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

--- Creates a `CheckChipGroup` with a chip per item quality, colored to match.
--- @param options QualityTogglesComponentOptions
--- @return WaffleFlexComponent root
function ComponentFactory:QualityToggles(options)
  --- @type CheckChipComponentOptions[]
  local chips = {}

  for _, quality in ipairs(QUALITIES) do
    chips[#chips + 1] = {
      text = quality.text,
      color = quality.color,
      get = function() return options.get(quality.key) end,
      set = function(value) options.set(quality.key, value) end
    }
  end

  return ComponentFactory:CheckChipGroup({ chips = chips, spread = true })
end
