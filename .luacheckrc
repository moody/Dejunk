std = "lua51"

exclude_files = {
  "./libs",
  "./locales",
}

ignore = {
  "211", -- Unused local variable.
  "212", -- Unused argument.
}

globals = {
  "DejunkBindings_ToggleOptionsFrame",
  "DejunkBindings_ToggleSellFrame",
  "DejunkBindings_ToggleDestroyFrame",
  "DejunkBindings_OpenLootables",
  "DejunkBindings_AddToList",
  "DejunkBindings_RemoveFromList",
  "DejunkBindings_StartSelling",
  "DejunkBindings_SellNextItem",
  "DejunkBindings_StartDestroying",
  "DejunkBindings_DestroyNextItem",
}
