local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local OptionsBuilder = Addon:GetModule("OptionsBuilder")

--- @class MainWindowOptions
local MainWindowOptions = Addon:GetModule("MainWindowOptions")

-- ============================================================================
-- MainWindowOptions - Key Bindings
-- ============================================================================

--- Creates the panel of key bindings.
--- @return TitledPanelComponent panel
function MainWindowOptions:CreateKeyBindingsPanel()
  local panel = OptionsBuilder:CreatePanel({
    titleText = Colors.Blue(L.KEYBINDS),
    titleJustify = "LEFT"
  })

  return panel
end
